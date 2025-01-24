#!/bin/bash
# syntax: [--default] <servername>
# short: Configure a new server

function exit_syntax
{
  echo "Syntax: runkit create-server [--default] [--baseport <port>] [--source <sourcedir>] [--image <image>] <server>"
  echo "  --default  sets the baseport to 13679 and binds the server to the 'wh' alias"
  echo "  --source   override WebHare source tree to use"
  echo "  --image    install container using specified image"
  echo "  <server>   short name for the server, used as wh-<server> alias"
  exit 1
}

source "${BASH_SOURCE%/*}/__servercreation.sh" || die "cannot load function library"
SOURCEROOT=""
IMAGE=""
WHDATA=""
QUIET=""

while true; do
  if [ "$1" == "--default" ]; then
    shift
    PRIMARY="1"
  elif [ "$1" == "--baseport" ]; then
    shift
    BASEPORT="$1"
    shift
  elif [ "$1" == "--source" ]; then
    shift
    SOURCEROOT="$1"
    shift
  elif [ "$1" == "--image" ]; then
    shift
    IMAGE="$1"
    shift
  elif [ "$1" == "--whdata" ]; then
    shift
    WHDATA="$1"
    shift
  elif [ "$1" == "--recreate" ]; then
    RECREATE="1"
    shift
  elif [ "$1" == "--nopull" ]; then
    NOPULL="1"
    shift
  elif [ "$1" == "--quiet" ]; then
    QUIET="1"
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
[ -n "$WHRUNKIT_TARGETSERVER" ] || exit_syntax
prepare_newserver #aborts if server already exists

WEBHARE_DATAROOT=""

mkdir -p "$WHRUNKIT_TARGETDIR"
if [ -n "$WHDATA" ]; then
  echo "$WHDATA" > "$WHRUNKIT_TARGETDIR/dataroot"
else
  mkdir -p "$WHRUNKIT_TARGETDIR/whdata"
  rm -f "$WHRUNKIT_TARGETDIR/dataroot"
fi

if [ -n "$IMAGE" ]; then
  configure_runkit_podman
  set_webhare_image
else
  rm -f "$WHRUNKIT_TARGETDIR/container.image"
fi


#TODO allow creating the PRIMARY installation
echo "$BASEPORT" > "$WHRUNKIT_TARGETDIR/baseport"
[ -n "$SOURCEROOT" ] && echo "$SOURCEROOT" > "$WHRUNKIT_TARGETDIR/sourceroot"

loadtargetsettings # reload to ensure we have loaded baseport/data settings

if [ -z "$QUIET" ]; then
  echo "Server created. To start: 'runkit @$WHRUNKIT_TARGETSERVER run-webhare' and access the server on http://127.0.0.1:$(($WEBHARE_BASEPORT))"
  echo "Don't forget to run 'runkit-reload' to activate the 'wh-$WHRUNKIT_TARGETSERVER' command"
fi
