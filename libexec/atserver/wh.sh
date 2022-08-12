#!/bin/bash
# command: wh ....
# short: Invoke a 'wh' action inside a WebHare

if [ "$1" == "freshdbconsole" ]; then
  echo "Use: runkit @$WHRUNKIT_TARGETSERVER" "$@"
  exit 1
fi

exec "$WHRUNKIT_WHCOMMAND" "$@"
