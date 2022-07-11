#!/bin/bash

if [ ! -x /usr/local/opt/opensearch-dashboards/bin/opensearch-dashboards ]; then
  echo "You need to brew install opensearch-dashboards" 1>&2
  exit 1
fi

/usr/local/opt/opensearch-dashboards/bin/opensearch-dashboards --opensearch.hosts="http://127.0.0.1:$((WEBHARE_BASEPORT + 6))/" --port="$((WEBHARE_BASEPORT + 7))" &
open "http://127.0.0.1:$((WEBHARE_BASEPORT + 7))/"
