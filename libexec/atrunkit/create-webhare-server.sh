#!/bin/bash

WHRUNKIT_TARGETSERVER="$1"
validate_servername "$WHRUNKIT_TARGETSERVER"
WEBHARE_DATAROOT=""
loadtargetsettings

if [ -d "$WEBHARE_DATAROOT" ] || [ -f "$WHRUNKIT_TARGETDIR/baseport" ]; then
  echo "Server '$WHRUNKIT_TARGETSERVER' already exists"
  exit 1
fi

#TODO allow creating the PRIMARY installation
mkdir -p "$WHRUNKIT_TARGETDIR/whdata"
echo "$(( RANDOM / 10 * 10 + 20000 ))" > "$WHRUNKIT_TARGETDIR/baseport"
loadtargetsettings

echo "Server created. To start: 'runkit @$WHRUNKIT_TARGETSERVER wh console' and access the server on http://127.0.0.1:$(($WEBHARE_BASEPORT + 9 ))"
echo "Don't forget to run 'runkit-reload' to activate the 'wh-$WHRUNKIT_TARGETSERVER' command"
