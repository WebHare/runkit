#!/bin/bash
# command: wh ....
# short: Invoke a 'wh' action inside a WebHare

if [ "$1" == "freshdbconsole" ]; then
  echo "Use: runkit @$WHRUNKIT_TARGETSERVER" "$@"
  exit 1
fi

if [ -n "$WHRUNKIT_CONTAINERNAME" ]; then #inside a container
  exec "$WHRUNKIT_ORIGCOMMAND" "@$WHRUNKIT_TARGETSERVER" enter wh "$@"
else
  exec "$WHRUNKIT_WHCOMMAND" "$@"
fi
