#!/bin/bash
ERROR=""
echo -n "runkit-proxy: "
if podman inspect runkit-proxy >/dev/null 2>&1;  then
  echo "up" # TODO more status checks?
elif [ -f /etc/systemd/system/runkit-proxy.service ] ; then
  echo "DOWN"
  ERROR=1
else
  echo "not installed"
fi

[ -n "$ERROR" ] && die "Errors!"
exit 0
