#!/bin/bash

# short: Fix system configuration for WebHare

if [ "$(uname)" != "Linux" ]; then
  # perhaps we'll add a macos version in the future to at least fix launchctl ulimit?
  echo "system-setup is only supported for linux"
  exit 1
fi

mkdir -p "$WHRUNKIT_DATADIR/_log"
LOGFILE="$WHRUNKIT_DATADIR/_log/system-setup.log"


echo "date=$(date)" > "$LOGFILE"
echo "uptime=$(uptime)" >> "$LOGFILE"

OVERCOMMIT="$(cat /proc/sys/vm/overcommit_memory)"
echo "overcommit=$OVERCOMMIT" >> "$LOGFILE"

if [ "$OVERCOMMIT" == "0" ] || [ "$OVERCOMMIT" == "2" ]; then
  echo "Fixing overcommit setting, WebHare requires 1, was: $OVERCOMMIT"
  echo 1 > /proc/sys/vm/overcommit_memory
fi

# Disable selinux. we're not compatible with enforcing mode yet (eg proxy won't start)
echo "selinux=$(getenforce)" >> "$LOGFILE"
setenforce 0

# Enable access to http
if hash firewall-cmd 2>/dev/null ; then
  firewall-cmd --zone=public --add-service=http
  firewall-cmd --zone=public --add-service=https
fi

exit 0
