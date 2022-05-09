#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: proxy-webhare.sh"
  echo "Establish our local proxy for all WebHares on this server"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"

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

if ! iscontainerup runkit-proxy ; then
  echo "The proxy is not running."
  exit 1
fi

WEBHARE_CONTAINERS="$(docker ps --filter=label=runkittype=webhare -q)"
if [ -z "$WEBHARE_CONTAINERS" ]; then
  echo "No WebHare containers found"
  exit 1
fi

PROXY_PASSWORD="$(docker exec runkit-proxy /opt/container/get-proxy-key.sh)"
if [ -z "$PROXY_PASSWORD" ]; then
  echo "Unable to retrieve the proxy's password"
  exit 1
fi

for ID in $WEBHARE_CONTAINERS ; do
  # TODO webhare needs to offer an atomic update so we don't risk downtime
  # although webserver reset might be sufficiently safe?
  docker exec "$ID" wh webserver reset --force
  WEBHARE_IP="$(docker inspect $ID |jq -r '.[0].NetworkSettings.Networks["webhare-runkit"].IPAddress')"
  #use the dedicated admin port because /admin/ may not be available (to make it available we have to deal with giving the proxy a proper hostname, and eventually letsencrypt)
  #TOOD to not have to deal with ignoring certificates, why can't the proxy open up its http-port using a command line option?
  docker exec "$ID" wh cli addproxy https://10.15.19.254:5443/ "$PROXY_PASSWORD" "http://$WEBHARE_IP:13684/"
done
