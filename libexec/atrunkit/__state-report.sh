#!/bin/bash

REPORTSTATEURL=$(cat /opt/runkit-data/_settings/upload-state-urls)
if [ -z "$REPORTSTATEURL" ]; then
  exit 0
fi

while read -r POSTURL; do
  echo "$STATE" | curl --silent --request POST --fail --data-binary "@-" "$POSTURL" > /dev/null
done <<<"$REPORTSTATEURL"
