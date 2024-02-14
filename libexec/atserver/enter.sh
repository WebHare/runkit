#!/bin/bash

# short: Open a shell inside the container

[ -n "$WHRUNKIT_CONTAINERNAME" ] || die "Not running in a container"
iscontainerup "$WHRUNKIT_CONTAINERNAME" || die "Container $WHRUNKIT_CONTAINERNAME is not running"

# we're not using nsenter --all now, it doesn't inherit the  containers environment

if [ "$1" != "" ]; then #sending a command
  EXECOPTS="-i"
  CMD=("$@")
else
  EXECOPTS="-ti"
  CMD=("/bin/bash")
fi

exec "$WHRUNKIT_CONTAINERENGINE" exec $EXECOPTS "$WHRUNKIT_CONTAINERNAME" env WEBHARE_CLI_USER="$WEBHARE_CLI_USER" PS1="[$(hostname --short)%${WHRUNKIT_TARGETSERVER} \W]\$ " "${CMD[@]}"
