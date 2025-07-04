#!/bin/bash
# syntax: <servername> <destination>
# short: Restore a server's data

set -e #fail on any uncaught error

exit_syntax()
{
  cat << HERE
Syntax: runkit restore-data [options] <servername> <destination>
        --archive arc          Archive to restore (defaults to latest)
HERE
  echo " "
  exit 1
}

RESTOREARCHIVE=""
BORGOPTIONS=(--progress)

while true; do
  if [ "$1" == "--archive" ]; then
    shift
    RESTOREARCHIVE="$1"
    shift
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
DOWNLOADTO="$2"
[ -z "$CONTAINER" ] && exit_syntax
[ -z "$DOWNLOADTO" ] && exit_syntax

resolve_whrunkit_command
applyborgsettings "$CONTAINER"

# Check if DOWNLOADTO directory is empty
if [ -d "$DOWNLOADTO" ] && [ "$(ls -A "$DOWNLOADTO")" ]; then
  die "Destination directory '$DOWNLOADTO' is not empty, refusing to restore data into it"
fi

download_backup "$RESTOREARCHIVE" "$DOWNLOADTO"
