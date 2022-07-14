#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: restore-backup.sh [--restoreto dir] <settingsname>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"
RESTORETO=""
RESTOREARCHIVE=""
BORGPATHS=""

while true; do
  if [ "$1" == "--restoreto" ]; then
    shift
    RESTORETO="$1"
    shift
  elif [ "$1" == "--archive" ]; then
    shift
    RESTOREARCHIVE="$1"
    shift
  elif [ "$1" == "--dbaseonly" ]; then
    shift
    BORGPATHS="sh:**/preparedbackup/"
  elif [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

CONTAINER="$1"
[ -z "$CONTAINER" ] && exit_syntax

ensurecommands borg ssh-add

if [ -z "$RESTORETO" ]; then
  RESTORETO="${WEBHARE_RUNKIT_RESTORETO:-/containerstorage}/$CONTAINER"
fi

mkdir -p "$RESTORETO"
cd "$RESTORETO"

applyborgsettings "$CONTAINER"

# Note: STATEDIR is legacy (When runkit was just for backups) and SERVERCONFIGDIR is for `runkit ...` commands
SERVERCONFIGDIR="$WHRUNKIT_ROOT/local/$CONTAINER/"
STATEDIR="$WEBHARE_RUNKIT_ROOT/local/state/$CONTAINER"
mkdir -p "$STATEDIR" "$SERVERCONFIGDIR"

if [ -z "$RESTOREARCHIVE" ]; then
  RESTOREARCHIVE="$(borg list --short --last 1)"
  [ -z "$RESTOREARCHIVE" ] && echo "No archive found!" && exit 1
  echo "Restoring archive $RESTOREARCHIVE"
else
  # borg will print error messages to stderr (like "Archive ... does not exist")
  borg info "::$RESTOREARCHIVE" > /dev/null || exit 1
fi

# FIXME this only applies for webhare restores, we need a more generic 'hey, you're overwriting an earlier restore!'' thing..
if [ -d "$RESTORETO/whdata" ]; then
  echo "Target directory $RESTORETO/whdata already exists!"
  exit 1
fi

echo "$RESTOREARCHIVE" > "$STATEDIR/restore.archive"
echo "$BORG_REPO" > "$STATEDIR/restore.borgrepo"
  echo "$RESTORETO" > "$STATEDIR/restore.to"
echo "" > "$STATEDIR/restore.source"

echo "$RESTOREARCHIVE" > "$SERVERCONFIGDIR/restore.archive"
echo "$BORG_REPO" > "$SERVERCONFIGDIR/restore.borgrepo"

# remove any existing restore directory
[ -d incomingrestore ] && rm -rf incomingrestore
mkdir incomingrestore
cd incomingrestore
borg extract --progress "::$RESTOREARCHIVE" $BORGPATHS # note: without --progress its a bit faster to start
cd ..
exit 0
