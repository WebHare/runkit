#!/bin/bash
# short: Open a shell inside the container

[ -n "$WHRUNKIT_CONTAINERNAME" ] || die "Not running in a container"
iscontainerup "$WHRUNKIT_CONTAINERNAME" || die "Container $WHRUNKIT_CONTAINERNAME is not running"

PID="$( podman inspect -f '{{.State.Pid}}' "$WHRUNKIT_CONTAINERNAME" )"

export WEBHARE_BASEPORT=13679 #Inside a container the baseport is always 13679
# Note: WH5.5 will explicitly set WEBHARE_BASEPORT=13679 in its container environment

# NOTE: only gnu understands `hostname --short``, Mac needs `-s`
[ -n "$RUNKIT_TARGET_SLUG" ] || RUNKIT_TARGET_SLUG="$WHRUNKIT_TARGETSERVER@$(hostname -s)"
PS1="[$RUNKIT_TARGET_SLUG \W]\$ "
export PS1
export RUNKIT_TARGET_SLUG

if [[ "$OSTYPE" != "darwin"* ]] && [ "$(id -u)" = 0 ]; then
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
    exec nsenter --all -t "$PID" wh shell
  fi
else
  if [ "$1" != "" ]; then
    exec podman exec --env PS1 --env RUNKIT_TARGET_SLUG -it "$WHRUNKIT_CONTAINERNAME" "$@"
  else
    exec podman exec --env PS1 --env RUNKIT_TARGET_SLUG -it "$WHRUNKIT_CONTAINERNAME" wh shell
  fi
fi
