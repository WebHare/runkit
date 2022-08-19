#!/bin/bash
# syntax: <containername>
# short: List available backups

set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: list-backups.sh"
  exit 1
}

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

CONTAINER="$1"
ensurecommands ssh-add borg
applyborgsettings "$CONTAINER" #Sets WHRUNKIT_TARGETSERVER

exec borg list
