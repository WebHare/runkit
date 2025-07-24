#!/bin/bash
# syntax: <image>
# short: Upgrade a docker-based server

function exit_syntax
{
  echo "Syntax: runkit @server upgrade <image>"
  echo "  image can be either:"
  echo "  - the full image path, eg: docker.io/webhare/platform:release-5-6"
  echo "  - a short name, eg: release/5.6, following the most recent 5.6.x version"
  echo "  - a semantic version, eg: 5.6.3"
  echo ""
  echo "WebHare server '$WHRUNKIT_TARGETSERVER' is currently running: $WHRUNKIT_CONTAINERIMAGE"
  exit 1
}
ENABLECONTAINER=
while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [ "$1" == "--nopull" ]; then
    NOPULL=1
    shift
  elif [ "$1" == "--enablecontainer" ]; then
    ENABLECONTAINER=1
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
[ -z "$ENABLECONTAINER" ] && [ -z "$WHRUNKIT_CONTAINERNAME" ] && die "This WebHare is not configured to run in a container. Use --enablecontainer to explicitly convert it"

configure_runkit_podman
set_webhare_image # consumes $IMAGE and $NOPULL

# TODO If converting from non-container to container, we should probably stop the server first

if iscontainerup "$WHRUNKIT_CONTAINERNAME" ; then
  echo "container is running, restart it! If controlled by systemd: runkit @$WHRUNKIT_TARGETSERVER run-webhare --as-service"
else
  echo "container is not running - not restarting it"
fi

exit 0
