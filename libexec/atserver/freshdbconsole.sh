#!/bin/bash
# short: Invokes 'freshdb' and starts a wh console if succesful.

if ! "$WHRUNKIT_ORIGCOMMAND" "@$WHRUNKIT_TARGETSERVER" freshdb ; then
  exit 1 #freshdb failed and should have reported why. we'll cancel
fi

shift
exec "$WHRUNKIT_WHCOMMAND" console "$@"
