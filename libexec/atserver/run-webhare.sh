#!/bin/bash

# short: Run this WebHare

# Use --showunitfile to debug the generated unit file

set -eo pipefail

exit_syntax()
{
  echo "Syntax: runkit @server run-webhare [--detach] [--rescue] [--showunitfile]"
  exit 1
}

DETACH=""
CONTAINER_CMDLINE=()
CONTAINEROPTIONS=()
ASSERVICE=""
REQUIREUNITS=()
NOSTART=""
SHOWUNITFILE=""

while true; do
  if [ "$1" == "--detach" ]; then
    DETACH="1"
    shift
  elif [ "$1" == "--rescue" ]; then
    CONTAINER_CMDLINE+=("/bin/bash")
    CONTAINEROPTIONS+=(-ti)
    shift
  elif [ "$1" == "--dockeropt" ] || [ "$1" == "--containeroption" ]; then
    shift
    CONTAINEROPTIONS+=("$1")
    shift
  elif [ "$1" == "--privileged" ]; then
    CONTAINEROPTIONS+=(--privileged)
    shift
  elif [ "$1" == "--requireunit" ]; then
    shift
    REQUIREUNITS+=("$1")
    shift
  elif [ "$1" == "--publishrescueport" ]; then
    shift
    [ -n "$1" ] || die "No port specified for --publishrescueport"
    CONTAINEROPTIONS+=(--publish "$1:13679/tcp")
    CONTAINEROPTIONS+=(--env WEBHARE_RESCUEPORT_BINDIP=0.0.0.0)
    shift
  elif [ "$1" == "--as-service" ]; then
    ASSERVICE="1"
    shift
  elif [ "$1" == "--showunitfile" ]; then
    ASSERVICE="1"
    SHOWUNITFILE="1"
    shift
  elif [ "$1" == "--prepare" ]; then
    NOSTART="1"
    shift
  elif [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

[ -n "$1" ] && exit_syntax

CMDLINE=()

if [ -n "$ASSERVICE" ]; then
  while read -r unit; do
    REQUIREUNITS+=("$unit")
  done < <(grep -E '^[-a-z0-9_:.]+$' "$WHRUNKIT_TARGETDIR"/required-units 2>/dev/null || true)

  for UNIT in "${REQUIREUNITS[@]}"; do
    if [ -n "$SHOWUNITFILE" ]; then
      echo "# would execute: systemctl start $UNIT"
    elif [ -z "$NOSTART" ]; then
      systemctl start "$UNIT" # start all of the required units, they may mount the whdata partition
    fi
  done
fi

mkdir -p "$WEBHARE_DATAROOT" #Ensure the dataroot is there

if [ -n "$WHRUNKIT_CONTAINERNAME" ]; then
  configure_runkit_podman

  # when not installing as a service, kill the current container
  [ -z "$ASSERVICE" ] && killcontainer "$WHRUNKIT_CONTAINERNAME"

  USEIMAGE="$(cat "$WHRUNKIT_TARGETDIR"/container.image)"
  # Looks like we have to launch this WebHare using podman

  if [ "$DETACH" == "1" ]; then
    CONTAINEROPTIONS+=(--detach)
  else
    CONTAINEROPTIONS+=(--rm)
  fi

  get_runkit_var NETWORKPREFIX networkprefix
  USEIP="$(cat "$WHRUNKIT_TARGETDIR"/container.ipv4 2>/dev/null || true)"
  if [ -z "$USEIP" ]; then
    (
      [ "$(uname)" == "Darwin" ] || flock -s 200 # No flock on macOS, but we'll take our chances as macOS is not server-production-ready anyway
      # Find a free IP address
      for LASTOCTET in $(seq 2 253) ; do
        ISINUSE=0
        USEIP="${NETWORKPREFIX}.${LASTOCTET}"
        for IP in $(cat "$WHRUNKIT_DATADIR"/*/container.ipv4 2>/dev/null || true); do
          if [ "$IP" == "$USEIP" ]; then
            ISINUSE=1
            break;
          fi
        done
        if [ "$ISINUSE" == "0" ]; then
          break;
        fi
      done
      [ "$ISINUSE" == "0" ] || die "Unable to find a free IP address"
      echo "$USEIP" > "$WHRUNKIT_TARGETDIR"/container.ipv4
    ) 200>"$WHRUNKIT_DATADIR"/.lock
    USEIP="$(cat "$WHRUNKIT_TARGETDIR"/container.ipv4 2>/dev/null || true)"
  fi

 # if [ -z "$WHRUNKIT_TARGETDIR"/container.ipv4 ]; then
#    # Allocate a free IP address under

  MOUNTFLAGS=""
  if [[ "$OSTYPE" != "darwin"* ]]; then
    # MOUNTFLAGS=":Z" #on darwin this triggers lsetxattr error, see https://github.com/containers/podman-compose/issues/509#issuecomment-1162988103
    CONTAINEROPTIONS+=(--security-opt label=disable)
  else
    CONTAINEROPTIONS+=(--user="$(id -u):$(id -g)" --userns=keep-id)
  fi

  CMDLINE+=(podman run -v "$WEBHARE_DATAROOT:/opt/whdata$MOUNTFLAGS")

  # --sdnotify=conmon - WH doesn't support NOTIFY_SOCKET yet so a succesful container start will have to do for readyness (https://docs.podman.io/en/v4.4/markdown/options/sdnotify.html)
  if [ -n "$ASSERVICE" ]; then
    CONTAINEROPTIONS+=(--sdnotify=conmon)
  fi

  if [ -f "$WHRUNKIT_TARGETDIR/environment" ]; then
    CONTAINEROPTIONS+=(--env-file "$WHRUNKIT_TARGETDIR/environment")
  fi

  if [ -f "$WHRUNKIT_TARGETDIR/container-options" ]; then
    while IFS= read -r line; do
      CONTAINEROPTIONS+=("$(printf '%q' "$line")")
    done < "$WHRUNKIT_TARGETDIR/container-options"
  elif [ -f "$WHRUNKIT_TARGETDIR/docker-options" ]; then #fallback to old name
    while IFS= read -r line; do
      CONTAINEROPTIONS+=("$(printf '%q' "$line")")
    done < "$WHRUNKIT_TARGETDIR/docker-options"
  fi

  # Added --no-hosts - this easily breaks connectivity to the proxy server if it's aliased to ::1
  CMDLINE+=(-h "$WHRUNKIT_TARGETSERVER".docker
               --network "$WHRUNKIT_NETWORKNAME"
               --ip "$USEIP"
               -e TZ=Europe/Amsterdam
               --label runkittype=webhare
               --log-opt max-size=50m
               --log-opt max-file=5
              --shm-size 1gb
               --no-hosts
               --name "$WHRUNKIT_CONTAINERNAME"
               "${CONTAINEROPTIONS[@]}"
               "$USEIMAGE"
               "${CONTAINER_CMDLINE[@]}")

else
  if [ -f "$WHRUNKIT_TARGETDIR"/environment ]; then
    # Read environment line-by-line, export all variables
    # shellcheck disable=SC1090
    eval $(sed 's/^\(.*\)=\(.*\)/export \1="\2"/' < "$WHRUNKIT_TARGETDIR"/environment)
  fi
  CMDLINE=("$WHRUNKIT_WHCOMMAND" console)
fi

if [ -n "$ASSERVICE" ]; then
  configure_runkit_podman

  if ! hash systemctl 2>/dev/null ; then
    echo "No systemctl - cannot install webhare --as-service"
    exit 1
  fi

# In the interest of server stability, we will not put any runkit code on the webhare-startup path
# TODO using a temp file is nicer
OUTPUTFILE="$(mktemp)"
  cat > "$OUTPUTFILE" << HERE
# This unitfile was generated by webhare-runkit's run-webhare.sh ($(cat "$WHRUNKIT_ROOT"/version) $( (cd "$WHRUNKIT_ROOT" && git rev-parse --short HEAD) 2>/dev/null))
[Unit]
Description=WebHare ${WHRUNKIT_TARGETSERVER}
After=podman.service ${REQUIREUNITS[@]}
Requires=podman.service ${REQUIREUNITS[@]}

[Service]
TimeoutStartSec=0
Restart=always
Type=notify
NotifyAccess=all

# Ensure any existing container gets out of the way. TODO stop this from making 'not found' noise in the log
ExecStartPre=-podman stop $WHRUNKIT_CONTAINERNAME
ExecStartPre=-podman rm -f -v $WHRUNKIT_CONTAINERNAME

# Start the container
ExecStart=${CMDLINE[@]}

# Signal hooks about container restart. This can be used to eg. update external monitoring immediately
ExecStartPost=-"$WHRUNKIT_ROOT/bin/runkit" __oncontainerchange started "$WHRUNKIT_CONTAINERNAME"
ExecStopPost=-"$WHRUNKIT_ROOT/bin/runkit" __oncontainerchange stopped "$WHRUNKIT_CONTAINERNAME"

# Tell systemd to use podman for shutdowns or it will try to signal conmon which won't understand
ExecStop=-podman stop $WHRUNKIT_CONTAINERNAME

[Install]
WantedBy=multi-user.target
HERE

  if [ -n "$SHOWUNITFILE" ]; then
    cat "$OUTPUTFILE"
    exit 0
  fi
  mv "$OUTPUTFILE" "/etc/systemd/system/$WHRUNKIT_CONTAINERNAME.service"
  restorecon "/etc/systemd/system/$WHRUNKIT_CONTAINERNAME.service" 2>/dev/null || true #Fix secutity settings as it will be messed up by the mktemp source. Ignore if failed

  systemctl daemon-reload
  systemctl enable "$WHRUNKIT_CONTAINERNAME" #ensure autostart
  if [ -z "$NOSTART" ]; then
    systemctl restart "$WHRUNKIT_CONTAINERNAME"
  fi
  exit 0
fi

exec "${CMDLINE[@]}"
