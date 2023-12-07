#!/bin/bash

# short: Report on available containers and whether they are running

ERROR=""
echo -n "runkit-proxy: "

PROXY_PID="$("$WHRUNKIT_CONTAINERENGINE" inspect -f '{{.State.Pid}}' "runkit-proxy" 2>/dev/null)"
if [ -n "$PROXY_PID" ]; then
  echo "up, pid=$PROXY_PID" # TODO more status checks?
elif [ -f /etc/systemd/system/runkit-proxy.service ] ; then
  echo "DOWN"
  ERROR=1
else
  echo "not installed"
fi

[ -n "$ERROR" ] && die "Errors!"

echo "(TODO: add webhares)"

exit 0
