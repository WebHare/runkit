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
  elif [ "$1" == "--privileged" ]; then
    DOCKEROPTS+=(--privileged)
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

if [ -n "$WHRUNKIT_CONTAINERNAME" ]; then
  killcontainer "$WHRUNKIT_CONTAINERNAME"

  USEIMAGE="$(cat "$WHRUNKIT_TARGETDIR"/container.image)"
  # Looks like we have to launch this WebHare using podman

  if [ "$DETACH" == "1" ]; then
    DOCKEROPTS+=(--detach)
  else
    DOCKEROPTS+=(--rm)
  fi

  USEIP="$(cat "$WHRUNKIT_TARGETDIR"/container.ipv4 2>/dev/null || true)"
  if [ -z "$USEIP" ]; then
    # Find a free IP address
    for LASTOCTET in $(seq 2 253) ; do
      ISINUSE=0
      USEIP="${WHRUNKIT_NETWORKPREFIX}.${LASTOCTET}"
      for IP in $(cat $WHRUNKIT_DATADIR/*/container.ipv4 2>/dev/null || true); do
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
    echo $USEIP > "$WHRUNKIT_TARGETDIR"/container.ipv4
  fi

 # if [ -z "$WHRUNKIT_TARGETDIR"/container.ipv4 ]; then
#    # Allocate a free IP address under

  echo "Creating WebHare container $WHRUNKIT_CONTAINERNAME"
  podman run -v "$WEBHARE_DATAROOT:/opt/whdata":Z \
             -h "$WHRUNKIT_TARGETSERVER".docker \
             --network "$WHRUNKIT_NETWORKNAME" \
             --ip "$USEIP" \
             -e TZ=Europe/Amsterdam \
             --label runkittype=webhare \
             --name "$WHRUNKIT_CONTAINERNAME" \
             "${DOCKEROPTS[@]}" \
             "$USEIMAGE" \
             $STARTUPOPT
else
  exec "$WHRUNKIT_WHCOMMAND" console
fi
