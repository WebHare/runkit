#!/bin/bash

set -eo pipefail

exit_syntax()
{
  echo "Syntax: runkit run-proxy [--sh] [--rescue]"
  exit 1
}


DETACH=""
TORUN=()
DOCKEROPTS=()
RESCUE=0
SYSTEMD=
ASSERVICE=

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [ "$1" == "--sh" ]; then
    TORUN=("/bin/bash")
    DOCKEROPTS+=("-t" "-i")
    shift
  elif [ "$1" == "--as-service" ]; then
    ASSERVICE="1"
    shift
  elif [ "$1" == "--systemd" ]; then
    SYSTEMD=1
    shift
  elif [ "$1" == "--rescue" ]; then
    TORUN=("/bin/sleep 604800")
    shift
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

[ -n "$1" ] && exit_syntax

mkdir -p "$WHRUNKIT_DATADIR/_proxy" # Ensure our datadir is there

# FIXME use last STABLE
[ -f "$WHRUNKIT_DATADIR/_proxy/container.image" ] || echo docker.io/webhare/proxy:master > "$WHRUNKIT_DATADIR/_proxy/container.image"

CONTAINERSTORAGE="$(cat "$WHRUNKIT_DATADIR/_proxy/dataroot" 2>/dev/null || true)"
if [ -z "$CONTAINERSTORAGE" ]; then # not explicitly set
  if [[ $(uname) == "Darwin" ]]; then
    CONTAINERSTORAGE="runkit-proxy-data" # Use a volume so the container can do its chown things and we can test those. proxy container contents are rarely interesting to access on the Mac host
  else
    CONTAINERSTORAGE="$WHRUNKIT_DATADIR/_proxy/data"
  fi
fi

CONTAINERBASENAME="proxy"
CONTAINERNAME="runkit-$CONTAINERBASENAME"
configure_runkit_podman

mkdir -p "$CONTAINERSTORAGE"
RUNIMAGE="$( cat "$WHRUNKIT_DATADIR/_proxy/container.image" )"

if [ -f "$WHRUNKIT_DATADIR/_settings/letsencryptemail" ]; then
  DOCKEROPTS+=(-e WEBHAREPROXY_LETSENCRYPTEMAIL="$(cat "$WHRUNKIT_DATADIR/_settings/letsencryptemail")")
fi
if [ -f "$WHRUNKIT_DATADIR/_settings/publichostname" ]; then
  DOCKEROPTS+=(-e WEBHAREPROXY_ADMINHOSTNAME="$(cat "$WHRUNKIT_DATADIR/_settings/publichostname")")
fi

# TODO support system docker/podman options eg
# - setting a recognizable hostname for the LB?  (eg  "-h" "lb-fra1-19.docker")
# - seting WEBHAREPROXY_ADMINHOSTNAME=do-fra1-19.hw.webhare.net
# - setting WEBHAREPROXY_LETSENCRYPTEMAIL=webhare-servermgmt+letsencypt@webhare.nl
# - setting DNS: "--dns=192.168.198.128" "--dns=8.8.8.8" "--dns=8.8.4.4"
# /opt/webhare-cloud/libexec/run-container.sh  "lb-fra1-19" "-h" "lb-fra1-19.docker" "-e" "TZ=Europe/Amsterdam" "-e" "NGINXPROXY_LOCALHOSTPORT=5442" "-e" "WEBHAREPROXY_ADMINHOSTNAME=do-fra1-19.hw.webhare.net" "-e" "WEBHAREPROXY_LETSENCRYPTEMAIL=webhare-servermgmt+letsencypt@webhare.nl" "--net" "host" "-v" "/opt/dockerstorage/lb-fra1-19/webhare-proxy-data:/opt/webhare-proxy-data/" "--dns=192.168.198.128" "--dns=8.8.8.8" "--dns=8.8.4.4" "--ulimit" "core=0"

if [ "$(uname)" == "Darwin" ]; then
  DOCKEROPTS+=(--publish 10080:80/tcp --publish 10443:443/tcp)
else
  DOCKEROPTS+=(--network host)

  if [ -z "$SYSTEMD" ] && [ -z "$ASSERVICE" ] && [ "$(systemctl is-active $CONTAINERNAME)" == "active" ]; then
    echo "You need to 'systemctl stop $CONTAINERNAME' before attemping to start us in the foreground"
    exit 1
  fi
fi

if [ "$ASSERVICE" ]; hten
  DOCKEROPTS+=(--sdnotify=conmon)
fi

DOCKEROPTS+=(--volume "$CONTAINERSTORAGE:/opt/webhare-proxy-data:Z"
              -e TZ=Europe/Amsterdam
              --name "$CONTAINERNAME"
              --label runkittype=proxy
              "--ulimit" "core=0"
              --sdnotify=conmon
              --log-opt max-size=50m
              --log-opt max-file=5
              "${RUNIMAGE:-}"
              "${TORUN[@]}"
             )

cleanup()
{
  if [ -n "$CONTAINERID" ]; then
    echo "- Stopping container $CONTAINERID ($CONTAINERNAME)"
    "$WHRUNKIT_CONTAINERENGINE" stop "$CONTAINERID"

    [ -x "$WHRUNKIT_DATADIR/_settings/containerchange.sh" ] && "$WHRUNKIT_DATADIR/_settings/containerchange.sh" stopped "$CONTAINERID" "$CONTAINERNAME"

    CONTAINERID=""
  fi
}


# Wrap into function to prevent updates from affecting running scripts
main()
{
  echo "- Stopping any existing container"
  "$WHRUNKIT_CONTAINERENGINE" stop "$CONTAINERNAME" 2>/dev/null
  "$WHRUNKIT_CONTAINERENGINE" rm -f -v "$CONTAINERNAME" 2>/dev/null

  echo "- Creating new container"
  CONTAINERID=$("$WHRUNKIT_CONTAINERENGINE" create --rm "${DOCKEROPTS[@]}")

  if [ -z "$CONTAINERID" ]; then
    echo Creation failed
    exit 1
   fi

  echo "- Starting it"
  if ! "$WHRUNKIT_CONTAINERENGINE" start $CONTAINERNAME ; then
    echo Startup failed
    exit 1
   fi

  trap cleanup EXIT INT TERM

  if [ "$(uname)" != "Darwin" ]; then
    PID="$("$WHRUNKIT_CONTAINERENGINE" inspect -f '{{.State.Pid}}' $CONTAINERNAME)"
    mkdir -p /runkit-containers/
    rm /runkit-containers/$CONTAINERBASENAME 2> /dev/null
    ln -s /proc/$PID/root /runkit-containers/$CONTAINERBASENAME
  fi

  echo "===== vvv $CONTAINERNAME vvvv ============"
  "$WHRUNKIT_CONTAINERENGINE" attach $CONTAINERNAME &
  attachpid=$!

  wait $attachpid

  echo "===== ^^^ $CONTAINERNAME stopped ========= (attach returned status code $?)"
}

if [ -n "$ASSERVICE" ]; then

  configure_runkit_podman

  if ! hash systemctl 2>/dev/null ; then
    echo "No systemctl - cannot install proxy"
    exit 1
  fi

  # In the interest of server stability, we will not put any runkit code on the proxy startup path

  # TODO using a temp file is nicer
  cat > "/etc/systemd/system/runkit-proxy.service" << HERE
[Unit]
Description=runkit proxy
After=podman.service
Requires=podman.service

[Service]
TimeoutStartSec=0
Restart=always
Type=notify
NotifyAccess=all

ExecStartPre=-"$WHRUNKIT_CONTAINERENGINE" stop runkit-proxy
ExecStartPre=-"$WHRUNKIT_CONTAINERENGINE" rm -f -v runkit-proxy
ExecStart="$WHRUNKIT_CONTAINERENGINE" run --rm ${DOCKEROPTS[@]}
ExecStartPost=-"$WHRUNKIT_ROOT/bin/runkit" __oncontainerchange started runkit-proxy
ExecStopPost=-"$WHRUNKIT_ROOT/bin/runkit" __oncontainerchange stopped runkit-proxy

[Install]
WantedBy=multi-user.target
HERE

  systemctl daemon-reload
  systemctl enable runkit-proxy #ensure autostart
  systemctl start runkit-proxy

  echo "Proxy initialized as unit"
  exit 0
fi

main "$@"
