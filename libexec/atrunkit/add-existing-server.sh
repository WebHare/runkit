#!/bin/bash
# command: add-existing-server <server> <datadir>
# short: Configure an already existing server to be managed by runkit

set -e

PRIMARY=""
BASEPORT=""

function exit_syntax
{
  echo "Syntax: runkit add-existing-server [--primary] [--baseport <port>] <server> <datadir>]"
  echo "        --primary  sets the baseport to 13679 and binds the server to the 'wh' alias"
  echo "        <server>   short name for the server, used as wh-<server> alias"
  echo "        <datadir>  where your data is currently stored (eg ~/projects/whdata/myserver/)"
}

while true; do
  if [ "$1" == "--primary" ]; then
    shift
    PRIMARY="1"
  elif [ "$1" == "--baseport" ]; then
    shift
    BASEPORT="$1"
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
if [ -z "$2" ]; then
  exit_syntax
fi

if [ -n "$PRIMARY" ]; then
  if [ -n "$BASEPORT" ]; then
    die You cannot set both --primary and --baseport
  fi
  BASEPORT=13679
fi

if [ -z "$BASEPORT" ]; then
  BASEPORT="$(( RANDOM / 10 * 10 + 20000 ))"
  # FIXME Check if in use
fi

validate_servername "$WHRUNKIT_TARGETSERVER"

DATADIRECTORY="$( (cd "$2" 2>/dev/null && pwd ) || true)" #'pwd' ensures this path won't end with a /
if [ -z "$DATADIRECTORY" ] || [ ! -d "$DATADIRECTORY/postgresql" ]; then
  echo "$2 does not appear to be a WebHare installation (no postgresql dir)" 2>&1
  exit 1
fi

WHRUNKIT_TARGETDIR="$WHRUNKIT_DATADIR/$WHRUNKIT_TARGETSERVER/"
if [ -d "$WHRUNKIT_TARGETDIR" ] && [ -d "$WHRUNKIT_TARGETDIR/postgresql" ]; then
  echo "Installation $WHRUNKIT_TARGETSERVER already exists" 2>&1
  exit 1
fi

for SERVER in $( cd "$WHRUNKIT_DATADIR" ; echo * ); do
  if [ "$SERVER" != "$WHRUNKIT_TARGETSERVER" ] && [ "$(cat "$WHRUNKIT_DATADIR/$SERVER/dataroot" 2>/dev/null)" == "$DATADIRECTORY" ]; then
    echo "Installation $NAME already points to $DATADIRECTORY" 2>&1
    exit 1
  fi
done

mkdir -p "$WHRUNKIT_TARGETDIR"

echo "$DATADIRECTORY" > "$WHRUNKIT_TARGETDIR/dataroot"
# TODO check for conflicting port numbers, and always avoid the builtin 13679-13689 range
echo "$BASEPORT" > "$WHRUNKIT_TARGETDIR/baseport"
echo "Created metadata for WebHare server '$WHRUNKIT_TARGETSERVER'"
