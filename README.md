# WebHare run kit
Tools for running WebHare on servers and testing backup/restore procedures

Download this repository using either of
- `git clone git@gitlab.com:webhare/runkit.git webhare-runkit`
- `git clone https://gitlab.com/webhare/runkit.git webhare-runkit`

Place any `*.borg` credentials you received in `webhare-runkit/local`.

## Getting data out of a borg host
If the data to restore is on a borg host (eg borgbase, rsync.net) you'll
need to download it first. Our scripts assume you'll have a credential file
set up for the container to restore. This credential file should have the
following structure.

```bash
BORG_PRIVATEKEY="-----BEGIN OPENSSH PRIVATE KEY-----
....key data....
-----END OPENSSH PRIVATE KEY-----"
BORG_REPO="user@host.repo.borgbase.com:repo"
BORG_PASSPHRASE="key passphrase"
```

Assuming credentials are in `webhare-runkit/local/demo.borg`, you can use
`webhare-runkit/open-backup.sh demo` to 'open' this backup (where opening is
defined as 'setting up borg to connect to this backup')

eg:

```bash
bin/open-backup.sh demo
borg list
```

will show you the available backups.

To restore the data (including database) for a WebHare installation named 'demo':
`bin/restore-webhare-data.sh demo`

To launch this WebHare in 'is restored' mode (which should prevent dangerous
automatic actions adn task from running): `bin/launch-webhare.sh demo`. This will
run in the foreground.

To watch the logs for a running WebHare: `bin/watch-webhare.sh demo`

Keep in mind that if you run all this on a mac, WebHare's database will be running
over a Docker volume mount and eg. index reconstruction after the restore can take
quite some time, especially if this installation isn't using postgres yet.

## Restoring a WebHare installation from 'data'

## NOTES
if you keep this webhare running, you'll need to remove 'whdata/preparedbackup'

# Testing and audits
- To verify backups are being made, follow the "Getting data out of a borg host"
  above steps and stop at `borg list`. You should be able to see which backups
  are present.
