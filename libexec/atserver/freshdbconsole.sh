#!/bin/bash

if "$WHRUNKIT_WHCOMMAND" isrunning ; then
  echo "Shutdown WebHare first"
  exit 1
fi

ALLOWFRESHFILE="$WEBHARE_DATAROOT/etc/allow-fresh-db"
if [ ! -f "$ALLOWFRESHFILE" ]; then
  die "freshdbconsole WIPES YOUR DATABASE on startup. To prove this is what you wish, please create a file named '$ALLOWFRESHFILE'"
fi

rm -rf -- "$WEBHARE_DATAROOT"/postgresql
rm -rf -- "$WEBHARE_DATAROOT"/log "$WEBHARE_DATAROOT"/system.cache "$WEBHARE_DATAROOT"/publisher.pb "$WEBHARE_DATAROOT"/publisher.pd "$WEBHARE_DATAROOT"/system.last-shrinkwrap-var
rm -rf -- "$WEBHARE_DATAROOT"/index "$WEBHARE_DATAROOT"/opensearch

if [ -x "$WEBHARE_DATAROOT/etc/fresh-db-setup.sh" ]; then  # TODO too many startup approaches - can WEBHARE_POSTSTARTSCRIPT solve this?
  "$WEBHARE_DATAROOT/etc/fresh-db-setup.sh" &
fi

shift
exec "$WHRUNKIT_WHCOMMAND" console "$@"
