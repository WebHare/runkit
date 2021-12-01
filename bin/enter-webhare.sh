#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: enter-webhare.sh <containername>"
  exit 1
}

WEBHARE_RUNKIT_ROOT="${BASH_SOURCE%/*/*}"

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

CONTAINER="$1"
shift

# Install dependencies
if ! hash jq docker 2>&1 ; then
  "$WEBHARE_RUNKIT_ROOT/bin/setup.sh"
fi

[ -z "$CONTAINER" ] && exit_syntax
CONTAINERNAME="runkit-$CONTAINER"

CONTAINERINFO="$(docker inspect "$CONTAINERNAME")"
if [ "$?" != "0" ]; then
  echo "Container $CONTAINERNAME does not seem to be running"
  exit 1
fi

exec docker exec -ti "$CONTAINERNAME" /bin/bash "$@"
