#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: open-backup.sh <settingsname>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/runkit-functions.sh"

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
[ -z "$CONTAINER" ] && exit_syntax

ensurecommands ssh-add borg
applyborgsettings "$CONTAINER"
echo ""
echo "To list available backups, use: borg list"
echo "To log out of this backup, use: exit"

export PS1="[$WHRUNKIT_TARGETSERVER] ${PS1:-\h:\W \u\$ }"
exec $SHELL
