#!/bin/bash
# command: wh ....
# short: Invoke a 'wh' action inside a WebHare

if [ "$1" == "freshdbconsole" ]; then
  echo "Use: runkit @$WHRUNKIT_TARGETSERVER" "$@"
  exit 1
fi

if [ -n "$WHRUNKIT_CONTAINERNAME" ]; then
  # it should be safe to assume its running inside docker
  DOCKEROPTS="-i"
  if [ -t 0 ] ; then
    DOCKEROPTS="-ti"
  fi
  exec "$WHRUNKIT_CONTAINERENGINE" exec $DOCKEROPTS "$WHRUNKIT_CONTAINERNAME" wh "$@"
fi

exec "$WHRUNKIT_WHCOMMAND" "$@"
