#!/bin/bash
set -e #fail on any uncaught error
source "${BASH_SOURCE%/*}/../libexec/functions.sh"

exit_syntax()
{
  echo "Syntax: startup-proxy-and-webhare.sh [--production] containers..."
  exit 1
}

PRODUCTION=""
while true; do
  if [ "$1" == "--production" ]; then
    shift
    PRODUCTION=1
  elif [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

[ -z "$1" ] && exit_syntax #need to specify one or more webhare containers

"$WHRUNKIT_ROOT"/bin/launch-proxy.sh --detach

for CONTAINER in "$@" ; do
  WEBHAREOPTS=""
  if [ "$PRODUCTION" == "1" ]; then
    WEBHAREOPTS="$WEBHAREOPTS --production"
  fi
  "$WHRUNKIT_ROOT"/bin/launch-webhare.sh --detach "$CONTAINER"
done

"$WHRUNKIT_ROOT"/bin/wait-proxy.sh

for CONTAINER in "$@" ; do
  # FIME 'started' should be enough but webhare doesn't announce that state, instead it pretends to be able to annouce 'poststart' but never does
  echo "Wait for WebHare '$CONTAINER' to reach 'poststartdone'"
  "$WHRUNKIT_ROOT"/bin/enter-webhare.sh "$CONTAINER" wh waitfor poststartdone
done

echo "Configure proxy servers"
"$WHRUNKIT_ROOT"/bin/proxy-webhare.sh

echo ""
echo "Servers are live!"
