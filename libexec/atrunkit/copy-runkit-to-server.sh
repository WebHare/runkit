#!/bin/bash

# short: Push locally updated runkit code to the specified server over SCP
if [ -z "$COPY_SSH_COMMAND" ]; then
  SERVER="$1"
  [ -z "$SERVER" ] && die "Server not specified"
  COPY_SSH_COMMAND="ssh $SERVER"
fi

# We want a runkit to be there already, or we might make a mistake copying ourselves..
REMOTERUNKITROOT="/opt/webhare-runkit/"
if ! $COPY_SSH_COMMAND test -x "$REMOTERUNKITROOT"/bin/runkit ; then
  die "runkit not initially installed (or needs to be moved to /opt/webhare-runkit)"
fi

( cd "$WHRUNKIT_ROOT" && tar -c -- * ) | $COPY_SSH_COMMAND tar -C "$REMOTERUNKITROOT" --warning=no-unknown-keyword -x
