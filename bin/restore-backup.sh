#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: restore-backup.sh <settingsname>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"
RESTOREARCHIVE=""
BORGPATHS=""

# note: without --progress its a bit faster to start
BORGOPTIONS=(--progress)

while true; do
  if [ "$1" == "--archive" ]; then
    shift
    RESTOREARCHIVE="$1"
    shift
  elif [ "$1" == "--dbaseonly" ]; then
    shift
    BORGPATHS="sh:**/preparedbackup/"
  elif [ "$1" == "--exclude" ]; then
    shift
    BORGOPTIONS+=(--exclude "$1")
    shift
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

applyborgsettings "$CONTAINER"
download_backup "$RESTOREARCHIVE" "$WHRUNKIT_TARGETDIR/download"
