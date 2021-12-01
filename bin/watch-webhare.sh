#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: watch-webhare.sh <containername>"
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
exec "$WEBHARE_RUNKIT_ROOT/bin/enter-webhare.sh" "$CONTAINER" wh watchlog
