# WebHare run kit
Tools for running WebHare on servers and testing backup/restore procedures

## Getting data out of a borg host
If the data to restore is on a borg host (eg borgbase, rsync.net) you'll
need to download it first. Our scripts assume you'll have a credential file
set up for the container to restore. This credential file should have the
following structure

```bash
BORG_PRIVATEKEY="-----BEGIN OPENSSH PRIVATE KEY-----
....key data....
-----END OPENSSH PRIVATE KEY-----"
BORG_REPO="user@host.repo.borgbase.com:repo"
BORG_PASSPHRASE="key passphrase"
```

This assumes credentials are in `webhare-runkit/local/demo`

```bash
webhare-runkit/bin/setup.sh
source /webhare-runkit/local/demo
mkdir -p /containers/demo
borg list
borg extract ::<lastest archive name, eg 20211201T081934-do-fra1-13>
```

Or a quick command for WebHare: `webhare-runkit/bin/restore-webhare-data.sh demo`

To launch this WebHare in restore mode: `webhare-runkit/bin/launch-webhare.sh demo`

Watch log issues: `webhare-runkit/bin/watch-webhare.sh demo`

Keep in mind that if you run all this on a mac, WebHare's database will be running
over a Docker volume mount and eg. index reconstruction after the restore can take
quite some time, especially if this installation isn't using postgres yet.

## Restoring a WebHare installation from 'data'


## NOTES
if you keep this webhare running, you'll need to remove 'whdata/preparedbackup'
