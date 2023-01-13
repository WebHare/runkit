#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: open-webhare.sh <containername>"
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

# We are migrating away from open-webhare..
echo "NOTE: If open-webhare fails, try runkit @$1 open"

loadtargetsettings

LAUNCHMODE="$(cat "$WHRUNKIT_TARGETDIR/launchmode")"

if [ "$LAUNCHMODE" == "docker" ]; then
  CONTAINERNAME="runkit-wh-$CONTAINER"
  ensurecommands jq docker
  CONTAINERINFO="$(docker inspect "$CONTAINERNAME")"
  if [ "$?" != "0" ]; then
    echo "Container $CONTAINERNAME does not seem to be running"
    exit 1
  fi

  RESCUEPORT="$(jq -r '.[0].NetworkSettings.Ports["13679/tcp"][0].HostPort' <<< "$CONTAINERINFO" )"
  if [ -z "$RESCUEPORT" ]; then # fall back to previous resue port (+9)
    RESCUEPORT="$(jq -r '.[0].NetworkSettings.Ports["13688/tcp"][0].HostPort' <<< "$CONTAINERINFO" )"
  fi
  if [ -z "$RESCUEPORT" ]; then
    echo "Unable to find the rescue port (13679 or 13688) for container $CONTAINERNAME"
    exit 1
  fi

  INTERFACEURL="http://127.0.0.1:$RESCUEPORT/"
elif [ "$LAUNCHMODE" == "native" ]; then
  RESCUEPORT=$((WEBHARE_BASEPORT + 9 ))
  INTERFACEURL="http://127.0.0.1:$RESCUEPORT/"
else
  echo "Unrecognized launchmode"
  exit 1
fi

echo "Rescue interface available on $INTERFACEURL"
if [ "$(uname)" == "Darwin" ]; then
  open "$INTERFACEURL"
fi
