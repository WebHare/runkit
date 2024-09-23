#!/bin/bash

# syntax: [--host bind to host] [--port port]
# short: Start OpenSearch dashboard for your local WebHare installation

function exit_syntax
{
  echo "Syntax: runkit create-server [--default] [--baseport <port>] <server>"
  echo "        --default  sets the baseport to 13679 and binds the server to the 'wh' alias"
  echo "        <server>   short name for the server, used as wh-<server> alias"
  echo "        <datadir>  where your data is currently stored (eg ~/projects/whdata/myserver/)"
  exit 1
}

DASHBOARD_HOST="127.0.0.1"
DASHBOARD_PORT="$((WEBHARE_BASEPORT + 7))"

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

if ! hash opensearch-dashboards 2>/dev/null; then
  echo "You need to install opensearch-dashboards" 1>&2
   [[ "$(uname)" == "Darwin" ]] && echo "Try: brew install opensearch-dashboards" 1>&2
  exit 1
fi

[ -n "$WEBHARE_OPENSEARCH_BINDHOST" ] || WEBHARE_OPENSEARCH_BINDHOST="127.0.0.1"
opensearch-dashboards --opensearch.hosts="http://$WEBHARE_OPENSEARCH_BINDHOST:$((WEBHARE_BASEPORT + 6))/" --host="$DASHBOARD_HOST" --port="$DASHBOARD_PORT" &

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
