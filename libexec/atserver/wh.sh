#!/bin/bash
# command: wh ....
# short: Invoke a 'wh' action inside a WebHare

if [ "$1" == "freshdbconsole" ]; then
  echo "Use: runkit @$WHRUNKIT_TARGETSERVER" "$@"
  exit 1
fi

if [ -f "$WHRUNKIT_TARGETDIR/container.image" ]; then
  # it should be safe to assume its running inside docker
  DOCKEROPTS="-i"
  if [ -t 0 ] ; then
    DOCKEROPTS="-ti"
  fi
  exec podman exec $DOCKEROPTS "runkit-wh-$WHRUNKIT_TARGETSERVER" wh "$@"
fi

exec "$WHRUNKIT_WHCOMMAND" "$@"
