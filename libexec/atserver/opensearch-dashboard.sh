#!/bin/bash

if [ ! -x /usr/local/opt/opensearch-dashboards/bin/opensearch-dashboards ]; then
  echo "You need to brew install opensearch-dashboards" 1>&2
  exit 1
fi

[ -n "$WEBHARE_OPENSEARCH_BINDHOST" ] || WEBHARE_OPENSEARCH_BINDHOST="127.0.0.1"
/usr/local/opt/opensearch-dashboards/bin/opensearch-dashboards --opensearch.hosts="http://$WEBHARE_OPENSEARCH_BINDHOST:$((WEBHARE_BASEPORT + 6))/" --port="$((WEBHARE_BASEPORT + 7))" &

trap "kill %1; wait %1" TERM EXIT

OPENURL="http://127.0.0.1:$((WEBHARE_BASEPORT + 7))/app/dev_tools#/console"

while true; do
  if curl --silent --fail "$OPENURL" >/dev/null 2>&1 ; then
    break # we have a connection
  fi
  sleep .3
done

open "$OPENURL"
wait %1
