#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: mount-backup.sh <settingsname> <archive>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

[ -t 0 ] || (echo "open-backup.sh requires a shell. if you use ssh, add the -t option" && exit 1)

CONTAINER="$1"
RESTOREARCHIVE="$2"
[ -z "$CONTAINER" ] && exit_syntax
[ -z "$RESTOREARCHIVE" ] && echo "No archive specified, gathering a list of archives..."

ensurecommands ssh-add borg
applyborgsettings "$CONTAINER" #Sets WHRUNKIT_TARGETSERVER
if [ -z "$2" ]; then
  borg list
  exit 0
fi

STATEDIR="$WEBHARE_RUNKIT_ROOT/local/state/$CONTAINER"

if [ -z "$RESTORETO" ]; then
  RESTORETO="$WHRUNKIT_DATADIR/$CONTAINER"
fi

RESTORESOURCE="/tmp/${CONTAINER}"

mkdir -p "$STATEDIR"
echo "$RESTOREARCHIVE" > "$STATEDIR/restore.archive"
echo "$BORG_REPO" > "$STATEDIR/restore.borgrepo"
echo "$RESTORETO" > "$STATEDIR/restore.to"
echo "$RESTORESOURCE" > "$STATEDIR/restore.source"

mkdir -p "$RESTORESOURCE"
borg mount -o ignore_permissions,defer_permissions "::$RESTOREARCHIVE" "$RESTORESOURCE"
echo "Mounted $RESTOREARCHIVE as $RESTORESOURCE"
echo "To unmount, use: borg umount $RESTORESOURCE"
echo "NOTE: No more backups can be made until you unmount!"
