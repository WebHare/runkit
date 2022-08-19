#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: launch-webhare.sh [--detach] <containername>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"

DETACH=""
NODOCKER=""

while true; do
  if [ "$1" == "--nodocker" ]; then #do not use docker to restore webhare
    NODOCKER="1"
    shift
  elif [ "$1" == "--detach" ]; then
    DETACH="1"
    shift
  elif [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

WHRUNKIT_TARGETSERVER="$1"
loadtargetsettings # sets WEBHARE_DATAROOT

# Install dependencies
if [ -z "$NODOCKER" ] && ! hash docker 2>/dev/null ; then
  "$WHRUNKIT_ROOT/bin/setup.sh"
fi

[ -z "$WHRUNKIT_TARGETSERVER" ] && exit_syntax

if [ ! -d "$WEBHARE_DATAROOT/dbase" ] && [ ! -d "$WEBHARE_DATAROOT/postgresql" ]; then
  echo "$WEBHARE_DATAROOT does not appear to contain a restored WebHare installation"
  exit 1
fi

if [ -z "$NODOCKER" ]; then
  CONTAINERNAME="runkit-wh-$WHRUNKIT_TARGETSERVER"
  DOCKEROPTS=""

  ensurecommands docker
  killcontainer "$CONTAINERNAME"
  configuredocker

  echo "docker" > "$WHRUNKIT_TARGETDIR/launchmode"
  RUNIMAGE=$( cat "$WHRUNKIT_TARGETDIR/docker.image" 2>/dev/null || true )


  if [ "$DETACH" == "1" ]; then
    DOCKEROPTS="$DOCKEROPTS --detach"
  else
    DOCKEROPTS="$DOCKEROPTS --rm"
  fi

  [ -e "$WHRUNKIT_TARGETDIR/docker.environment" ] && DOCKEROPTS="$DOCKEROPTS --env-file $WHRUNKIT_TARGETDIR/docker.environment"

  echo -n "Creating WebHare container $CONTAINERNAME: "
  docker run -i \
             -v "$WEBHARE_DATAROOT:/opt/whdata" \
             --network webhare-runkit \
             -h "$WHRUNKIT_TARGETSERVER".docker \
             -e TZ=Europe/Amsterdam \
             --label runkittype=webhare \
             --name "$CONTAINERNAME" \
             $DOCKEROPTS \
             "${RUNIMAGE:-webhare/platform:master}"
else
  if [ "$DETACH" == "1" ]; then
    echo "Detaching not supported for --nodocker runs (as wh console doesn't support it)"
    exit 1
  fi

  export WEBHARE_NOINSTALLATIONINFO=1
  echo "native" > "$WHRUNKIT_TARGETDIR/launchmode"
  exec "${BASH_SOURCE%/*}/runkit" @"$WHRUNKIT_TARGETSERVER" wh console
fi

exit 0
