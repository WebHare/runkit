#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  cat << HERE
Syntax: restore-webhare-symlinked.sh [options] <containername>
HERE
  echo " "
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"

CONTAINER="$1"
[ -z "$CONTAINER" ] && exit_syntax

STATEDIR="$WHRUNKIT_ROOT/local/state/$CONTAINER"

MOUNTPOINT="/tmp/$CONTAINER"
[ -d "$MOUNTPOINT" ] || ( echo "Mountpoint $MOUNTPOINT not found" && exit 1 )

WHDATAFOLDER="$(find "$MOUNTPOINT" -name whdata -print -quit)"
if [ -z "$WHDATAFOLDER" ] || ! [ -d "$WHDATAFOLDER/preparedbackup" ]; then
  echo "Cannot find the 'whdata' folder inside the backup, cannot continue the restore"
  exit 1
fi

if [ -z "$RESTORETO" ]; then
  [ -f "$STATEDIR/restore.to" ] || ( echo "--restoreto is required if you didn't restore the backup using runkit" 1>&2 && exit 1)
  RESTORETO="$(cat "$STATEDIR/restore.to")"
fi

if [ -z "$RESTORETO" ]; then
  RESTORETO="$WHRUNKIT_DATADIR/$CONTAINER"
fi

mkdir -p "$RESTORETO/whdata"
echo "Will restore to: $RESTORETO"

if ! hash wh 2>/dev/null ; then
  echo "'wh' command not found, but needed for a symlinkedrestore!"
  exit 1
fi

STATEDIR="$WHRUNKIT_ROOT/local/state/$CONTAINER"
mkdir -p "$STATEDIR"

WEBHARE_DATAROOT="$RESTORETO/whdata" wh restore --softlink "$WHDATAFOLDER/preparedbackup"
