#!/bin/bash

# short: Fix system configuration for WebHare

if [ "$(uname)" != "Linux" ]; then
  # perhaps we'll add a macos version in the future to at least fix launchctl ulimit?
  echo "system-setup is only supported for linux"
  exit 1
fi

OVERCOMMIT="$(cat /proc/sys/vm/overcommit_memory)"
if [ "$OVERCOMMIT" == "0" ] || [ "$OVERCOMMIT" == "2" ]; then
  echo "Fixing overcommit setting, WebHare requires 1, was: $OVERCOMMIT"
  echo 1 > /proc/sys/vm/overcommit_memory
fi

exit 0
