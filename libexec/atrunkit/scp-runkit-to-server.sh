#!/bin/bash

# short: Push locally updated runkit code to the specified server over SCP


SERVER="$1"
REMOTERUNKITROOT="/root/webhare-runkit/"
[ -z "$SERVER" ] && die "Server not specified"

# We want a runkit to be there already, or we might make a mistake copying ourselves..
ssh "$SERVER" test -x "$REMOTERUNKITROOT"/bin/runkit || die "runkit not initially installed"
scp -r "$WHRUNKIT_ROOT"/* "$SERVER":"$REMOTERUNKITROOT"
