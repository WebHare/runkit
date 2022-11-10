#!/bin/bash
# syntax: [--primary] <servername>
# short: Configure a new server

function exit_syntax
{
  echo "Syntax: runkit create-server [--primary] [--baseport <port>] [--source <sourcdir>] <server>"
  echo "  --primary  sets the baseport to 13679 and binds the server to the 'wh' alias"
  echo "  --source   override WebHare source tree to use"
  echo "  <server>   short name for the server, used as wh-<server> alias"
  exit 1
}

source "${BASH_SOURCE%/*}/__servercreation.sh" || die "cannot load function library"
SOURCEROOT=""

while true; do
  if [ "$1" == "--primary" ]; then
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
prepare_newserver

WEBHARE_DATAROOT=""

#TODO allow creating the PRIMARY installation
mkdir -p "$WHRUNKIT_TARGETDIR/whdata"
echo "$BASEPORT" > "$WHRUNKIT_TARGETDIR/baseport"
[ -n "$SOURCEROOT" ] && echo "$SOURCEROOT" > "$WHRUNKIT_TARGETDIR/sourceroot"

loadtargetsettings # reload to ensure we have loaded baseport/data settings

echo "Server created. To start: 'runkit @$WHRUNKIT_TARGETSERVER wh console' and access the server on http://127.0.0.1:$(($WEBHARE_BASEPORT + 9 ))"
echo "Don't forget to run 'runkit-reload' to activate the 'wh-$WHRUNKIT_TARGETSERVER' command"
