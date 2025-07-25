#!/bin/bash

# syntax: [--host bind to host] [--port port]
# short: Start OpenSearch dashboard for your local WebHare installation

function exit_syntax
{
  echo "Syntax: runkit [@server] [--host bind to host] [--port port] opensearch-dashboard"
  echo "        to connect to a WebHare outside a container try setting a non-127.0.0.1 IP in ~/whrunkit/<server>/opensearch-bindhost"
  exit 1
}

DASHBOARD_HOST="127.0.0.1"
DASHBOARD_PORT="$((WEBHARE_BASEPORT + 8))" #Often 13687

while true; do
  if [ "$1" == "--host" ]; then
    shift
    DASHBOARD_HOST="$1"
    shift
  elif [ "$1" == "--port" ]; then
    shift
    DASHBOARD_PORT="$1"
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

[ -n "$WEBHARE_OPENSEARCH_BINDHOST" ] || WEBHARE_OPENSEARCH_BINDHOST="127.0.0.1"

configure_runkit_podman

OPENSEARCH_HOSTS="http://$WEBHARE_OPENSEARCH_BINDHOST:$((WEBHARE_BASEPORT + 6))/"

#baseport +6 is often 13685 and is where OpenSearch should already be running
#opensearch-dashboards --opensearch.hosts="http://$WEBHARE_OPENSEARCH_BINDHOST:$((WEBHARE_BASEPORT + 6))/" --host="$DASHBOARD_HOST" --port="$DASHBOARD_PORT" &
OPTS=(--rm
      --interactive
      --name "osdashboard-$DASHBOARD_PORT"
      --publish "$DASHBOARD_PORT":5601
      --env OPENSEARCH_HOSTS="$OPENSEARCH_HOSTS"
      --env DISABLE_SECURITY_DASHBOARDS_PLUGIN=true
    )

podman run "${OPTS[@]}" opensearchproject/opensearch-dashboards:latest &
trap "kill %1; wait %1" TERM EXIT

OPENURL="http://$DASHBOARD_HOST:$DASHBOARD_PORT/app/dev_tools#/console"

while true; do
  if curl --silent --fail "$OPENURL" >/dev/null 2>&1 ; then
    break # we have a connection
  fi
  sleep .3
done

open "$OPENURL"
wait %1
