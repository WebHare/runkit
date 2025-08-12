#!/bin/bash

PROXYKEYPATH="$WHRUNKIT_DATADIR/_proxy/data/etc/secret.key"
if [ ! -e "$PROXYKEYPATH" ]; then
  echo "Admin key $PROXYKEYPATH not present" 1>&2
  exit 1
fi

ADMINKEY="$(cat "$PROXYKEYPATH")"
open "http://webhare:${ADMINKEY}@127.0.0.1:5080/"
exit 0
