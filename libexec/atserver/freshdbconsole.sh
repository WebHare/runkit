#!/bin/bash

if "$WHRUNKIT_WHCOMMAND" isrunning ; then
  echo "Shutdown WebHare first"
  exit 1
fi

# Make sure any known old scripts are gone
"$WHRUNKIT_WHCOMMAND" service force-terminate-all --kill || true # ignore errors

ALLOWFRESHFILE="$WEBHARE_DATAROOT/etc/allow-fresh-db"
if [ ! -f "$ALLOWFRESHFILE" ]; then
  die "freshdbconsole WIPES YOUR DATABASE on startup. To prove this is what you wish, please create a file named '$ALLOWFRESHFILE'"
fi

# Delete all whdata folders, except etc (where allow-fresh-db lives, but it should probably be in whrunkit folder) and modules
# Prevent unneeded geoip redownloads
rm -rf "$WEBHARE_DATAROOT"/previous-freshdb
mkdir -p "$WEBHARE_DATAROOT"/previous-freshdb
find "$WEBHARE_DATAROOT" -not -name previous-freshdb \
                         -not -name etc \
                         -not -name "installedmodules*" \
                         -not -name geoip \
                         -mindepth 1 -maxdepth 1 \
                         -exec mv {} "$WEBHARE_DATAROOT"/previous-freshdb/ ";"

if [ -x "$WEBHARE_DATAROOT/etc/fresh-db-setup.sh" ]; then  # TODO too many startup approaches - can WEBHARE_POSTSTARTSCRIPT solve this?
  "$WEBHARE_DATAROOT/etc/fresh-db-setup.sh" &
fi

shift
exec "$WHRUNKIT_WHCOMMAND" console "$@"
