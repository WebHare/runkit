#!/bin/bash

# short: Install system config, necessary packages according to WebHare's preferences

set -eo pipefail

if ! hash systemctl 2>/dev/null ; then
  echo "No systemctl - cannot install system-setup"
  exit 1
fi

# TODO using a temp file is nicer
cat > /etc/systemd/system/runkit-system-setup.service << HERE
[Unit]
Description=Automatically fix system configuration for WebHare

[Service]
Type=oneshot

# prefixing with /bin/bash prevents SELinux from complaining about running code from eg. /root/projects/
ExecStart=/bin/bash "$WHRUNKIT_ROOT"/bin/runkit system-setup

[Install]
WantedBy=multi-user.target
HERE

######### Runkit daily maintenance
cat > /etc/systemd/system/runkit-daily-maintenance.service << HERE
[Unit]
Description=runkit daily maintenance
Wants=runkit-daily-maintenance.timer

[Service]
Type=oneshot

# prefixing with /bin/bash prevents SELinux from complaining about running code from eg. /root/projects/
ExecStart=/bin/bash "$WHRUNKIT_ROOT"/bin/runkit __daily-maintenance

[Install]
WantedBy=multi-user.target
HERE

cat > /etc/systemd/system/runkit-daily-maintenance.timer << HERE
[Unit]
Description=runkit daily maintenance
Requires=runkit-daily-maintenance.service

[Timer]
Unit=runkit-daily-maintenance.service
OnCalendar=*-*-* 03:00:00

[Install]
WantedBy=multi-user.target
HERE

######### Load reporting
cat > /etc/systemd/system/runkit-load-report.service << HERE
[Unit]
Description=runkit load reporter
Wants=runkit-load-report.timer

[Service]
Type=oneshot

# prefixing with /bin/bash prevents SELinux from complaining about running code from eg. /root/projects/
ExecStart=/bin/bash "$WHRUNKIT_ROOT"/bin/runkit __load-report

[Install]
WantedBy=multi-user.target
HERE

cat > /etc/systemd/system/runkit-load-report.timer << HERE
[Unit]
Description=runkit load report
Requires=runkit-load-report.service

[Timer]
Unit=runkit-load-report.service
OnCalendar=*-*-* *:*:00

[Install]
WantedBy=multi-user.target
HERE

systemctl daemon-reload
systemctl enable --now runkit-system-setup.service
systemctl enable --now runkit-daily-maintenance.timer
systemctl enable --now runkit-load-report.timer

mkdir -p "$WHRUNKIT_DATADIR/_log"
cat "$WHRUNKIT_ROOT/version" > "$WHRUNKIT_DATADIR/_log/.last-install-system-version"
date > "$WHRUNKIT_DATADIR/_log/.last-install-system-date"

echo "System-setup initialized!"
