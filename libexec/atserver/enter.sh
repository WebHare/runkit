#!/bin/bash

# short: Open a shell inside the container

[ -n "$WHRUNKIT_CONTAINERNAME" ] || die "Not running in a container"
iscontainerup "$WHRUNKIT_CONTAINERNAME" || die "Container $WHRUNKIT_CONTAINERNAME is not running"
PID="$( "$WHRUNKIT_CONTAINERENGINE" inspect -f '{{.State.Pid}}' "$WHRUNKIT_CONTAINERNAME" )"

if [ "$1" != "" ]; then
  exec nsenter --all -t "$PID" "$@"
else
  PS1="[$(hostname --short)%${WHRUNKIT_TARGETSERVER} \W]\$ " nsenter --all -t "$PID" /bin/bash --noprofile --norc
fi
