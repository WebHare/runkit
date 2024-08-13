#!/bin/bash

# short: Install system config, necessary packages

set -eo pipefail

if hash systemctl 2>/dev/null ; then # check if systemctl is present, otherwise assume we're in a container or at least not responsible for system config

  # TODO using a temp file is nicer
cat > /etc/systemd/system/runkit-system-setup.service << HERE
[Unit]
Description=Automatically fix system configuration for WebHare

[Service]
Type=oneshot

ExecStart="$WHRUNKIT_ROOT"/bin/runkit system-setup

[Install]
WantedBy=multi-user.target
HERE

  systemctl daemon-reload
  systemctl enable runkit-system-setup #ensure autostart
  systemctl start runkit-system-setup

  echo "System-setup initialized!"
fi

addpackage borgbackup openssh-client podman jq
