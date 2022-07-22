#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: enter-webhare.sh <containername>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"

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

[ -z "$CONTAINER" ] && exit_syntax

STATEDIR="$WEBHARE_RUNKIT_ROOT/local/state/$CONTAINER"
LAUNCHMODE="$(cat $STATEDIR/launchmode)"

if [ "$LAUNCHMODE" == "docker" ]; then
  ensurecommands jq docker

  CONTAINERNAME="runkit-$CONTAINER"
  CONTAINERINFO="$(docker inspect "$CONTAINERNAME")"
  if [ "$?" != "0" ]; then
    echo "Container $CONTAINERNAME does not seem to be running"
    exit 1
  fi

  if [ -z "$*" ]; then
    exec docker exec -ti "$CONTAINERNAME" /bin/bash
  else
    exec docker exec -i "$CONTAINERNAME" "$@"
  fi
else
  WEBHARE_BASEPORT="$(cat "$STATEDIR/baseport")"
  WEBHARE_DATAROOT="$(cat "$STATEDIR/dataroot")"
  WEBHARE_SHELL_PS1_POSTFIX=" ($CONTAINER)"

  export WEBHARE_BASEPORT WEBHARE_DATAROOT WEBHARE_SHELL_PS1_POSTFIX
  if [ -z "$*" ]; then
    wh shell
  else
    "$@"
  fi
fi
