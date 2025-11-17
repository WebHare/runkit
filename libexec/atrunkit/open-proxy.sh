#!/bin/bash

PROXYKEYPATH="$WHRUNKIT_DATADIR/_proxy/data/etc/secret.key"
if [ ! -e "$PROXYKEYPATH" ]; then
  echo "Admin key $PROXYKEYPATH not present" 1>&2
  exit 1
fi

# TODO can we set an explcit nam
ADMINKEY="$(cat "$PROXYKEYPATH")"
WEBHAREPROXY_ADMINHOSTNAME="localhost"

if [ -f "$WHRUNKIT_DATADIR/_settings/publichostname" ]; then
  WEBHAREPROXY_ADMINHOSTNAME="$(cat "$WHRUNKIT_DATADIR/_settings/publichostname")"
fi

open "http://webhare:${ADMINKEY}@${WEBHAREPROXY_ADMINHOSTNAME}/admin"
exit 0
