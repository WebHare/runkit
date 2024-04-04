#!/bin/bash

# short: Open a shell inside the container

[ -n "$WHRUNKIT_CONTAINERNAME" ] || die "Not running in a container"
iscontainerup "$WHRUNKIT_CONTAINERNAME" || die "Container $WHRUNKIT_CONTAINERNAME is not running"

PID="$( "$WHRUNKIT_CONTAINERENGINE" inspect -f '{{.State.Pid}}' "$WHRUNKIT_CONTAINERNAME" )"

export WEBHARE_BASEPORT=13679 #Inside a container the baseport is always 13679
# Note: WH5.5 will explicitly set WEBHARE_BASEPORT=13679 in its container environment

# Note: future versions of nsenter will learn '--env' which will remove the need for this (it was added nov 2023)
# Import the target environment. You shouldn't target untrusted containers with this code!
while IFS= read -r LINE
do
  # shellcheck disable=SC2163 disable=SC2086
  export $LINE
done < <(xargs -0 -L1 -a "/proc/$PID/environ" | grep -E '^[A-Za-z0-9_]+=');

if [ "$1" != "" ]; then
   exec nsenter --all -t "$PID" "$@"
 else
  PS1="[$(hostname --short)%${WHRUNKIT_TARGETSERVER} \W]\$ " nsenter --all -t "$PID" /bin/bash --noprofile --norc
fi
