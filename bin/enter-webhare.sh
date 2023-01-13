#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: enter-webhare.sh <containername>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/runkit-functions.sh"

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

WHRUNKIT_TARGETSERVER="$1"
[ -z "$WHRUNKIT_TARGETSERVER" ] && exit_syntax
shift

loadtargetsettings

LAUNCHMODE="$(cat "$WHRUNKIT_TARGETDIR/launchmode")"

if [ "$LAUNCHMODE" == "docker" ]; then
  ensurecommands jq docker

  CONTAINERNAME="runkit-wh-$WHRUNKIT_TARGETSERVER"
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
  export WEBHARE_BASEPORT WEBHARE_DATAROOT WEBHARE_SHELL_PS1_POSTFIX
  if [ -z "$*" ]; then
    exec "${BASH_SOURCE%/*}/runkit" @"$WHRUNKIT_TARGETSERVER" shell
  else
    "$@"
  fi
fi
