#!/bin/bash

# FIXME get rid of ocnfiguralbe containerstorage... there should be _proxy/dataroot links like webhareh has

CONTAINERSTORAGE="$WHRUNKIT_DATADIR/_proxy/data"

exit_syntax()
{
  echo "Syntax: runkit run-proxy [--detach] [--containerstorage <dir>]"
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
configure_runkit_podman
killcontainer "$CONTAINERNAME"

mkdir -p "$CONTAINERSTORAGE"

RUNIMAGE=$( cat "$WHRUNKIT_DATADIR/_proxy/container.image" 2>/dev/null || true )

# FIXME use last STABLE

DOCKEROPTS=""
if [ "$DETACH" == "1" ]; then
  DOCKEROPTS="$DOCKEROPTS --detach"
else
  DOCKEROPTS="$DOCKEROPTS --rm"
fi


# TODO support system docker/podman options eg
# - setting a recognizable hostname for the LB?  (eg  "-h" "lb-fra1-19.docker")
# - seting WEBHAREPROXY_ADMINHOSTNAME=do-fra1-19.hw.webhare.net
# - setting WEBHAREPROXY_LETSENCRYPTEMAIL=webhare-servermgmt+letsencypt@webhare.nl
# - setting DNS: "--dns=192.168.198.128" "--dns=8.8.8.8" "--dns=8.8.4.4"
# /opt/webhare-cloud/libexec/run-container.sh  "lb-fra1-19" "-h" "lb-fra1-19.docker" "-e" "TZ=Europe/Amsterdam" "-e" "NGINXPROXY_LOCALHOSTPORT=5442" "-e" "WEBHAREPROXY_ADMINHOSTNAME=do-fra1-19.hw.webhare.net" "-e" "WEBHAREPROXY_LETSENCRYPTEMAIL=webhare-servermgmt+letsencypt@webhare.nl" "--net" "host" "-v" "/opt/dockerstorage/lb-fra1-19/webhare-proxy-data:/opt/webhare-proxy-data/" "--dns=192.168.198.128" "--dns=8.8.8.8" "--dns=8.8.4.4" "--ulimit" "core=0"

echo "Creating proxy container $CONTAINERNAME:"
podman run $DOCKEROPTS -i \
               -v "$CONTAINERSTORAGE:/opt/webhare-proxy-data" \
               --network host \
               -e TZ=Europe/Amsterdam \
               --name "$CONTAINERNAME" \
               --label runkittype=proxy \
               "--ulimit" "core=0" \
               "${RUNIMAGE:-docker.io/webhare/proxy:master}"

exit 0
