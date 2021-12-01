#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: open-webhare.sh <containername>"
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

if ! hash jq docker 2>/dev/null ; then
  "$WEBHARE_RUNKIT_ROOT/bin/setup.sh"
fi

[ -z "$CONTAINER" ] && exit_syntax
CONTAINERNAME="runkit-$CONTAINER"
STATEDIR="$WEBHARE_RUNKIT_ROOT/local/state/$CONTAINER"
LAUNCHMODE="$(cat $STATEDIR/launchmode)"

if [ "$LAUNCHMODE" == "docker" ]; then
  CONTAINERINFO="$(docker inspect "$CONTAINERNAME")"
  if [ "$?" != "0" ]; then
    echo "Container $CONTAINERNAME does not seem to be running"
    exit 1
  fi

  RESCUEPORT="$(jq -r '.[0].NetworkSettings.Ports["13688/tcp"][0].HostPort' <<< "$CONTAINERINFO" )"
  if [ -z "$RESCUEPORT" ]; then
    echo "Unable to find the rescue port (13688) for container $CONTAINERNAME"
    exit 1
  fi

  INTERFACEURL="http://127.0.0.1:$RESCUEPORT/"
elif [ "$LAUNCHMODE" == "native" ]; then
  RESCUEPORT=$(( $(cat $STATEDIR/baseport) + 9 ))
  INTERFACEURL="http://127.0.0.1:$RESCUEPORT/"
else
  echo "Unrecognized launchmode"
  exit 1
fi

echo "Rescue interface available on $INTERFACEURL"
if [ "$(uname)" == "Darwin" ]; then
  open "$INTERFACEURL"
fi
