#!/bin/bash

# short: Open a shell inside the container's network

[ -n "$WHRUNKIT_CONTAINERNAME" ] || die "Not running in a container"
iscontainerup "$WHRUNKIT_CONTAINERNAME" || die "Container $WHRUNKIT_CONTAINERNAME is not running"
PID="$( podman inspect -f '{{.State.Pid}}' "$WHRUNKIT_CONTAINERNAME" )"

if [ "$1" != "" ]; then
  exec nsenter -n -u -i -t "$PID" "$@"
else
  PS1="[$(hostname --short)%${WHRUNKIT_TARGETSERVER} (network) \W]\$ " nsenter -n -u -i -t "$PID" /bin/bash --noprofile --norc
fi
