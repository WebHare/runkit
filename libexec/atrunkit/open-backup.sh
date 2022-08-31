#!/bin/bash
# syntax: <servername>
# short: Open subshell with borg configured for the container

set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: runkit open-backup <servername>"
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

[ -t 0 ] || (echo "open-backup requires a shell. if you use ssh, add the -t option" && exit 1)

CONTAINER="$1"
[ -z "$CONTAINER" ] && exit_syntax

ensurecommands borg
applyborgsettings "$CONTAINER"
echo ""
echo "To list available backups, use: borg list"
echo "To log out of this backup, use: exit"

export PS1="[$WHRUNKIT_TARGETSERVER] ${PS1:-\h:\W \u\$ }"
exec $SHELL
