#!/bin/bash

# short: Push locally updated runkit code to the specified server over SCP
if [ -z "$COPY_SSH_COMMAND" ]; then
  SERVER="$1"
  [ -z "$SERVER" ] && die "Server not specified"
  COPY_SSH_COMMAND="ssh $SERVER"
fi

  # We want a runkit to be there already, or we might make a mistake copying ourselves..
REMOTERUNKITROOT="/opt/runkit-project/"
if ! $COPY_SSH_COMMAND test -x "$REMOTERUNKITROOT"/bin/runkit ; then
  REMOTERUNKITROOT="/root/webhare-runkit/"
  $COPY_SSH_COMMAND test -x "$REMOTERUNKITROOT"/bin/runkit || die "runkit not initially installed"
fi

( cd "$WHRUNKIT_ROOT" && tar -c -- * ) | $COPY_SSH_COMMAND tar -C "$REMOTERUNKITROOT" --warning=no-unknown-keyword -x
