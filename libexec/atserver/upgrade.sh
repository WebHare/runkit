#!/bin/bash
# syntax: <image>
# short: Upgrade a docker-based server

function exit_syntax
{
  echo "Syntax: runkit @server upgrade <image>"
  echo "WebHare server '$WHRUNKIT_TARGETSERVER' is currently running: $WHRUNKIT_CONTAINERIMAGE"
  exit 1
}

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [ "$1" == "--nopull" ]; then
    NOPULL=1
    shift
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

IMAGE="$1"

[ -n "$IMAGE" ] || exit_syntax
[ -n "$WHRUNKIT_CONTAINERNAME" ] || die "This WebHare is not in a Docker container"

configure_runkit_podman
fix_webhareimage_parameter

echo "$IMAGE" > "$WHRUNKIT_TARGETDIR/container.image"

if iscontainerup "$WHRUNKIT_CONTAINERNAME" ; then
  echo "container is running, restart it! If controlled by systemd: systemctl restart $WHRUNKIT_CONTAINERNAME"
else
  echo "container is not running - not restarting it"
fi
