#!/bin/bash
set -e #fail on any uncaught error
source "${BASH_SOURCE%/*}/../libexec/functions.sh"

CONTAINERSTORAGE="$WHRUNKIT_DATADIR/_proxy/data"

exit_syntax()
{
  echo "Syntax: launch-proxy.sh [--detach] [--containerstorage <dir>]"
  exit 1
}


DETACH=""

while true; do
  if [ "$1" == "--containerstorage" ]; then
    shift
    CONTAINERSTORAGE="$1"
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

[ -n "$1" ] && exit_syntax

CONTAINERNAME="runkit-proxy"
ensurecommands docker
killcontainer "$CONTAINERNAME"
configuredocker

mkdir -p "$CONTAINERSTORAGE"

RUNIMAGE=$( cat "$WHRUNKIT_DATADIR/_proxy/docker.image" 2>/dev/null || true )

# FIXME use last STABLE

DOCKEROPTS=""
if [ "$DETACH" == "1" ]; then
  DOCKEROPTS="$DOCKEROPTS --detach"
else
  DOCKEROPTS="$DOCKEROPTS --rm"
fi

echo -n "Creating proxy container $CONTAINERNAME: "
docker run $DOCKEROPTS -i \
           -v "$CONTAINERSTORAGE:/opt/webhare-proxy-data" \
           --network webhare-runkit \
           --ip 10.15.19.254 \
           -e TZ=Europe/Amsterdam \
           --publish 80:80 \
           --publish 443:443 \
           --publish 127.0.0.1:5443:5443 \
           --name "$CONTAINERNAME" \
           --label runkittype=proxy \
           "${RUNIMAGE:-webhare/proxy:master}"

exit 0
