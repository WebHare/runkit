#!/bin/bash

set -eo pipefail

exit_syntax()
{
  echo "Syntax: runkit @server uninstall-webhare"
  exit 1
}

while true; do
  if [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

[ -n "$1" ] && exit_syntax

if [ -z "$WHRUNKIT_CONTAINERNAME" ]; then
  die Cannot uninstall WebHare not running inside container
fi


systemctl stop "$WHRUNKIT_CONTAINERNAME"
systemctl disable "$WHRUNKIT_CONTAINERNAME"
systemctl daemon-reload

rm -f /etc/systemd/system/${WHRUNKIT_CONTAINERNAME}.service
find "$WHRUNKIT_TARGETDIR" -maxdepth 1 -mindepth 1 ! -name whdata -delete
rmdir "$WHRUNKIT_TARGETDIR" || true
