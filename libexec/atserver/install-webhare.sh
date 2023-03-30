#!/bin/bash

# short: configure this machine to start the specified WebHare at starutp

set -eo pipefail

configure_runkit_podman

if ! hash systemctl 2>/dev/null ; then
  echo "No systemctl - cannot install proxy"
  exit 1
fi

SERVICENAME="runkit-wh-$WHRUNKIT_TARGETSERVER"

# TODO using a temp file is nicer
cat > "/etc/systemd/system/$SERVICENAME.service" << HERE
[Unit]
Description=runkit proxy
After=podman.service
Requires=podman.service

[Service]
TimeoutStartSec=0
Restart=always

ExecStart="$WHRUNKIT_ROOT"/bin/runkit "@$WHRUNKIT_TARGETSERVER" run-webhare

[Install]
WantedBy=multi-user.target
HERE

systemctl daemon-reload
systemctl enable "$SERVICENAME" #ensure autostart
systemctl start "$SERVICENAME"

echo "WebHare $WHRUNKIT_TARGETSERVER initialized!"
