#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: launch-webhare.sh [--restoreto dir] [--detach] [--production] <containername>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"

DETACH=""
RESTORETO=""
NODOCKER=""
PRODUCTION=""

while true; do
  if [ "$1" == "--restoreto" ]; then
    shift
    RESTORETO="$1"
    shift
  elif [ "$1" == "--nodocker" ]; then #do not use docker to restore webhare
    NODOCKER="1"
    shift
  elif [ "$1" == "--production" ]; then #do not use docker to restore webhare
    PRODUCTION="1"
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

CONTAINER="$1"

# Install dependencies
if [ -z "$NODOCKER" ] && ! hash docker 2>/dev/null ; then
  "$WEBHARE_RUNKIT_ROOT/bin/setup.sh"
fi

[ -z "$CONTAINER" ] && exit_syntax

STATEDIR="$WEBHARE_RUNKIT_ROOT/local/state/$CONTAINER"
if [ -z "$RESTORETO" ]; then
  [ -f "$STATEDIR/restore.to" ] || ( echo "--restoreto is required if you didn't restore the backup using runkit" 1>&2 && exit 1)
  RESTORETO="$(cat "$STATEDIR/restore.to")"
fi

if [ ! -d "$RESTORETO/whdata/dbase" ] && [ ! -d "$RESTORETO/whdata/postgresql" ]; then
  echo "$RESTORETO does not appear to contain a restored WebHare installation"
  exit 1
fi

CONTAINERNAME="runkit-$CONTAINER"
mkdir -p "$STATEDIR"

if [ -n "$PRODUCTION" ]; then
  WEBHARE_ISRESTORED=""
elif [ -f "$STATEDIR/restore.archive" ]; then
  WEBHARE_ISRESTORED="Restored $(cat $STATEDIR/restore.archive) from $(cat $STATEDIR/restore.borgrepo)"
else
  WEBHARE_ISRESTORED="1"
fi

if [ -z "$NODOCKER" ]; then
  ensurecommands docker
  killcontainer "$CONTAINERNAME"
  configuredocker

  echo "docker" > "$STATEDIR/launchmode"
  RUNIMAGE=$( cat "$WEBHARE_RUNKIT_ROOT/local/$CONTAINER.dockerimage" 2>/dev/null || true )

  DOCKEROPTS=""

  if [ "$DETACH" == "1" ]; then
    DOCKEROPTS="$DOCKEROPTS --detach"
  else
    DOCKEROPTS="$DOCKEROPTS --rm"
  fi

  if [ "$PRODUCTION" != "1" ]; then
    DOCKEROPTS="$DOCKEROPTS -e WEBHARE_ISRESTORED='$WEBHARE_ISRESTORED'"
  fi

  echo -n "Creating WebHare container $CONTAINERNAME: "
  docker run $DOCKEROPTS -i \
             -v "$RESTORETO/whdata:/opt/whdata" \
             --network webhare-runkit \
             -h "$CONTAINER".docker \
             -e TZ=Europe/Amsterdam \
             -e WEBHARE_RESCUEPORT_BINDIP=0.0.0.0 \
             --expose 13688 \
             --publish-all \
             --label runkittype=webhare \
             --name "$CONTAINERNAME" \
             "${RUNIMAGE:-webhare/platform:master}"
else
  if [ "$DETACH" == "1" ]; then
    echo "Detaching not supported for --nodocker runs (as wh console doesn't support it)"
    exit 1
  fi

  export WEBHARE_ISRESTORED
  export WEBHARE_BASEPORT="$(( $RANDOM / 10 * 10 + 20000 ))"
  export WEBHARE_DATAROOT="$RESTORETO/whdata"

  # settings.sh overrides BASEPORT and DATAROOT and interferes with us. WebHare should re-evaluate whether wh restore generated settings.sh is really needed
  [ -f "$RESTORETO/whdata/settings.sh" ] && rm "$RESTORETO/whdata/settings.sh"
  echo "native" > "$STATEDIR/launchmode"
  echo "$WEBHARE_DATAROOT" > "$STATEDIR/dataroot"
  echo "$WEBHARE_BASEPORT" > "$STATEDIR/baseport"

  if ! hash wh 2>/dev/null ; then
    echo "'wh' command not found, but needed for a --nodocker launch!"
    exit 1
  fi

  wh console
fi

exit 0
