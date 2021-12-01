# WebHare run kit
Tools for running WebHare on servers and testing backup/restore procedures

## Getting data from borg
This assumes credentials are in `webhare-runkit/local/whlive-test-chatplane2`

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
