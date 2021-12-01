#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: launch-webhare.sh [--restoreto dir] <containername>"
  exit 1
}

WEBHARE_RUNKIT_ROOT="${BASH_SOURCE%/*/*}"
RESTORETO=""
NODOCKER=""

while true; do
  if [ "$1" == "--restoreto" ]; then
    shift
    RESTORETO="$1"
    shift
  elif [ "$1" == "--nodocker" ]; then #do not use docker to restore webhare
    NODOCKER="1"
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
if [ -z "$NODOCKER" ] && ! hash docker 2>&1 ; then
  "$WEBHARE_RUNKIT_ROOT/bin/setup.sh"
fi

[ -z "$CONTAINER" ] && exit_syntax

if [ -z "$RESTORETO" ]; then
  RESTORETO="/containerstorage/$CONTAINER"
fi

if [ ! -d "$RESTORETO/whdata/dbase" ] && [ ! -d "$RESTORETO/whdata/postgresql" ]; then
  echo "$RESTORETO does not appear to contain a restored WebHare installation"
  exit 1
fi

CONTAINERNAME="runkit-$CONTAINER"
STATEDIR="$WEBHARE_RUNKIT_ROOT/local/state/$CONTAINER"
mkdir -p "$STATEDIR"

if [ -z "$NODOCKER" ]; then
  if docker inspect "$CONTAINERNAME" > /dev/null 2>&1 ; then
    docker stop "$CONTAINERNAME" || true
    sleep 1
    docker kill "$CONTAINERNAME" || true
    docker rm -f "$CONTAINERNAME"
  fi

  if ! docker network inspect webhare-runkit > /dev/null 2>&1 ; then
    docker network create webhare-runkit --subnet=10.15.19.0/24 --ip-range=10.15.19.128/25
  fi

  echo "docker" > "$STATEDIR/$CONTAINER/launchmode"

  docker run --rm \
             -v "$RESTORETO/whdata:/opt/whdata" \
             --network webhare-runkit \
             -h "$CONTAINER".docker \
             -e TZ=Europe/Amsterdam \
             -e WEBHARE_RESCUEPORT_BINDIP=0.0.0.0 \
             -e WEBHARE_ISRESTORED=1 \
             --expose 13688 \
             --publish-all \
             --name "runkit-$CONTAINER" \
             webhare/platform:master
else
  export WEBHARE_ISRESTORED=1
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
