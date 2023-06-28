#!/bin/bash

# short: configure this machine to start the proxy at starutp

set -eo pipefail

configure_runkit_podman

if ! hash systemctl 2>/dev/null ; then
  echo "No systemctl - cannot install proxy"
  exit 1
fi

# TODO using a temp file is nicer
cat > /etc/systemd/system/runkit-proxy.service << HERE
[Unit]
Description=runkit proxy
After=podman.service
Requires=podman.service

[Service]
TimeoutStartSec=0
Restart=always

ExecStart="$WHRUNKIT_ROOT"/bin/runkit run-proxy --systemd

[Install]
WantedBy=multi-user.target
HERE

systemctl daemon-reload
systemctl enable runkit-proxy #ensure autostart
systemctl start runkit-proxy

echo "Proxy initialized!"
