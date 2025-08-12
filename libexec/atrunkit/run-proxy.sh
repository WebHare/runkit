#!/bin/bash

set -eo pipefail

exit_syntax()
{
  echo "Syntax: runkit run-proxy [--sh] [--detach] [--rescue] [--as-service]"
  exit 1
}

DETACH=""
TORUN=()
CONTAINEROPTIONS=()
ASSERVICE=
PREPARE=""
SETIMAGE=""

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [ "$1" == "--detach" ]; then
    DETACH="1"
    shift
  elif [ "$1" == "--sh" ]; then
    TORUN=("/bin/bash")
    CONTAINEROPTIONS+=("-t" "-i")
    shift
  elif [ "$1" == "--as-service" ]; then
    ASSERVICE="1"
    shift
  elif [ "$1" == "--rescue" ]; then
    TORUN=("/bin/sleep 604800")
    shift
  elif [ "$1" == "--prepare" ]; then
    PREPARE="1"
    shift
  elif [ "$1" == "--set-image" ]; then
    shift
    SETIMAGE="$1"
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

if [ -z "$SETIMAGE" ] && [ ! -f "$WHRUNKIT_DATADIR/_proxy/container.image" ]; then
  SETIMAGE="$WHRUNKIT_REGISTRYROOT/webhare/proxy:master" # TODO last stable version ? but we lack a branch for that
fi

if [ ! -f "$WHRUNKIT_DATADIR/_proxy/container.image" ] && [ -z "$SETIMAGE" ]; then
  SETIMAGE="master"
fi

if [ -n "$SETIMAGE" ]; then
  set_container_image "RESOLVEDIMAGE" "proxy" "$SETIMAGE"

  COMMITREF="$(podman image inspect "$RESOLVEDIMAGE" | jq -r '.[0].Labels["dev.webhare.proxy.git-commit-ref"]')"
  [ -z "$COMMITREF" ] && [ -z "$__WHRUNKIT_DISABLE_IMAGE_CHECK" ] && die "Image does not appear to be a WebHare proxy"

  echo "$SETIMAGE" > "$WHRUNKIT_DATADIR/_proxy/container.requestedimage"
  echo "$RESOLVEDIMAGE" > "$WHRUNKIT_DATADIR/_proxy/container.image"
fi

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

mkdir -p "$CONTAINERSTORAGE"
RUNIMAGE="$( cat "$WHRUNKIT_DATADIR/_proxy/container.image" )"

if [ -f "$WHRUNKIT_DATADIR/_settings/letsencryptemail" ]; then
  CONTAINEROPTIONS+=(-e WEBHAREPROXY_LETSENCRYPTEMAIL="$(cat "$WHRUNKIT_DATADIR/_settings/letsencryptemail")")
fi
if [ -f "$WHRUNKIT_DATADIR/_settings/publichostname" ]; then
  CONTAINEROPTIONS+=(-e WEBHAREPROXY_ADMINHOSTNAME="$(cat "$WHRUNKIT_DATADIR/_settings/publichostname")")
fi

# TODO support options eg
# - setting a recognizable hostname for the LB?  (eg  "-h" "lb-fra1-19.docker")
# - seting WEBHAREPROXY_ADMINHOSTNAME=do-fra1-19.hw.webhare.net
# - setting WEBHAREPROXY_LETSENCRYPTEMAIL=webhare-servermgmt+letsencypt@webhare.nl
# - setting DNS: "--dns=192.168.198.128" "--dns=8.8.8.8" "--dns=8.8.4.4"

if [ "$(uname)" == "Darwin" ]; then
  CONTAINEROPTIONS+=(--publish 10080:80/tcp --publish 10443:443/tcp)
else
  CONTAINEROPTIONS+=(--network host)

  if [ -z "$ASSERVICE" ] && [ "$(systemctl is-active $CONTAINERNAME)" == "active" ]; then
    echo "You need to 'systemctl stop $CONTAINERNAME' before attemping to start us in the foreground"
    exit 1
  fi
fi

# --sdnotify=conmon - our proxy doesn't support NOTIFY_SOCKET yet so a succesful container start will have to do for readyness (https://docs.podman.io/en/v4.4/markdown/options/sdnotify.html)
if [ -n "$ASSERVICE" ]; then
  CONTAINEROPTIONS+=(--sdnotify=conmon)
fi

if [ "$DETACH" == "1" ]; then
  CONTAINEROPTIONS+=(--detach)
else
  CONTAINEROPTIONS+=(--rm)
fi

CONTAINEROPTIONS+=(--volume "$CONTAINERSTORAGE:/opt/webhare-proxy-data:Z"
              -e TZ=Europe/Amsterdam
              --name "$CONTAINERNAME"
              --label runkittype=proxy
              "--ulimit" "core=0"
              --log-opt max-size=50m
              --log-opt max-file=5
              "${RUNIMAGE:-}"
              "${TORUN[@]}"
             )

# Wrap into function to prevent updates from affecting running scripts
main()
{
  echo "- Stopping any existing container"
  podman stop "$CONTAINERNAME" || true 2>/dev/null
  podman rm -f -v "$CONTAINERNAME" || true 2>/dev/null

  echo "- Starting new container"
  exec podman run "${CONTAINEROPTIONS[@]}"
}

if [ -n "$ASSERVICE" ]; then
  configure_runkit_podman

  if ! hash systemctl 2>/dev/null ; then
    echo "No systemctl - cannot install proxy --as-service."
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

ExecStartPre=-podman stop "$CONTAINERNAME"
ExecStartPre=-podman rm -f -v "$CONTAINERNAME"
ExecStart=podman run ${CONTAINEROPTIONS[@]}
ExecStartPost=-"$WHRUNKIT_ROOT/bin/runkit" __oncontainerchange started "$CONTAINERNAME"
ExecStopPost=-"$WHRUNKIT_ROOT/bin/runkit" __oncontainerchange stopped "$CONTAINERNAME"
# Tell systemd to use podman or it will try to signal conmon which won't understand
ExecStop=-podman stop $WHRUNKIT_CONTAINERNAME

[Install]
WantedBy=multi-user.target
HERE

  systemctl daemon-reload
  systemctl enable runkit-proxy #ensure autostart
  if [ -z "$PREPARE" ]; then
    systemctl restart runkit-proxy
  fi

  echo "Proxy initialized as unit"
  exit 0
fi

main "$@"
