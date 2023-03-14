#!/bin/bash
set -eo pipefail

exit_syntax()
{
  echo "Syntax: runkit @server run-webhare [--detach] [--rescue]"
  exit 1
}

DETACH=""
STARTUPOPT=""
DOCKEROPTS=()

while true; do
  if [ "$1" == "--detach" ]; then
    DETACH="1"
    shift
  elif [ "$1" == "--rescue" ]; then
    STARTUPOPT="/bin/bash"
    DOCKEROPTS+=(-ti)
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

configure_runkit_podman

if [ -f "$WHRUNKIT_TARGETDIR"/container.image ]; then
  CONTAINERNAME="runkit-wh-$WHRUNKIT_TARGETSERVER"
  killcontainer "$CONTAINERNAME"

  USEIMAGE="$(cat "$WHRUNKIT_TARGETDIR"/container.image)"
  # Looks like we have to launch this WebHare using podman

  if [ "$DETACH" == "1" ]; then
    DOCKEROPTS+=(--detach)
  else
    DOCKEROPTS+=(--rm)
  fi

  USEIP="$(cat "$WHRUNKIT_TARGETDIR"/container.ivp4 2>/dev/null || true)"
  if [ -z "$USEIP" ]; then
    # Find a free IP address
    for LASTOCTET in $(seq 1 253) ; do
      ISINUSE=0
      for IP in $(cat $WHRUNKIT_DATADIR/*/container.ipv4 2>/dev/null); do
        echo match $IP $USEIP
        if [ "$IP" == "$USEIP" ]; then
          ISINUSE=1
          break;
        fi
      done
      if [ "$ISINUSE" == "0" ]; then
        break;
      fi
    done
    [ "$ISINUSE" == "0" ] || die "Unable to find a free IP address"
    echo $USEIP > "$WHRUNKIT_TARGETDIR"/container.ivp4
  fi

 # if [ -z "$WHRUNKIT_TARGETDIR"/container.ipv4 ]; then
#    # Allocate a free IP address under

  echo "Creating WebHare container $CONTAINERNAME"
  podman run -v "$WEBHARE_DATAROOT:/opt/whdata" \
             -h "$WHRUNKIT_TARGETSERVER".docker \
             --network "$WHRUNKIT_NETWORKNAME" \
             --ip "$USEIP" \
             -e TZ=Europe/Amsterdam \
             --label runkittype=webhare \
             --name "$CONTAINERNAME" \
             "${DOCKEROPTS[@]}" \
             "$USEIMAGE" \
             $STARTUPOPT
fi

exit 1

CONTAINERNAME="runkit-proxy"
configure_runkit_podman

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

echo "Creating proxy container $CONTAINERNAME"
podman run $DOCKEROPTS -i \
               -v "$CONTAINERSTORAGE:/opt/webhare-proxy-data" \
               --network host \
               -e TZ=Europe/Amsterdam \
               --name "$CONTAINERNAME" \
               --label runkittype=proxy \
               "--ulimit" "core=0" \
               "${RUNIMAGE:-docker.io/webhare/proxy:master}"

exit 0
