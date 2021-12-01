#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: restore-backup.sh [--restoreto dir] <settingsname>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"
RESTORETO=""

while true; do
  if [ "$1" == "--restoreto" ]; then
    shift
    RESTORETO="$1"
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

if [ -z "$RESTORETO" ]; then
  RESTORETO="/containerstorage/$CONTAINER"
fi

mkdir -p "$RESTORETO"
cd "$RESTORETO"

applyborgsettings "$CONTAINER"

RESTOREARCHIVE="$(borg list --short --last 1)"
[ -z "$RESTOREARCHIVE" ] && echo "No archive found!" && exit 1

if [ -d "$RESTORETO/whdata" ]; then
echo "Target directory $RESTORETO/whdata already exists!"
exit 1
fi

# remove any existing restore directory
[ -d incomingrestore ] && rm -rf incomingrestore
mkdir incomingrestore
cd incomingrestore
borg extract --progress "::$RESTOREARCHIVE"  # note: without --progress its a bit faster to start
cd ..
exit 0
