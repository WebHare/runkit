# WebHare runkit
Tools for running WebHare on desktops and servers and testing backup/restore procedures

Download this repository using either of
- `git clone git@gitlab.com:webhare/runkit.git webhare-runkit`
- `git clone https://gitlab.com/webhare/runkit.git webhare-runkit`

To ease runkit use add `eval $(~/webhare-runkit/bin/runkit setupmyshell)` to your shell. You can then use `runkit-reload`
to reload the aliases without having to close your current session. You can also place just `runkit` in your path or invoke
it directly when invoking it. All examples below assume that `runkit` will invoke `bin/runkit` from this project.

Runkit will store its data in `$HOME/whrunkit/` or `/opt/whrunkit/` by default. You can override this directory by setting
the WHRUNKIT_ROOT environment varaible

## Managing WebHare installations
runkit offers the following subcommands:
- `add-existing-server <servername> <path>` - Add an already configured WebHare
- `create-webhare-server <servername>` - Set up a new installation with the given name

Examples:
```bash
# Sets up a new server (will be initialized by invoking 'runkit @mytest console')
runkit create-webhare-server mytest

# Adds ~/projects/whdata/myserver as your primary installation
runkit add-existing-server --primary myserver ~/projects/whdata/myserver
```

The primary installation is the one with baseport '13679' and will be bound to the `wh` alias by runkit's setupmyshell.
Other installs are bound to a `wh-server` alias eg `wh-mytest`. You can always target a server using `runkit @<server> ...`.

## Restoring WebHare backups
Our scripts assume you'll have a credential file set up for the server you are restoring.
Paste these credentials into `runkit set-borg-credentails <server>` and test the credentials
by entering `runkit list-backups <server>`.

### Restore mode
`runkit restore-server` will create a file `webhare.restoremode` in the `whdata`
directory with details about which archive was restored. The presence of this file
will cause WebHare to launch in 'restore mode'.

To exit restore mode, run `wh exit-restore-mode`. This will restart WebHare!

### Restore recipes
These recipes assume you are logged in to the server on which you will be
restoring WebHare and that you have set CONTAINER to the server you're restoring
(eg `CONTAINER=demo`)

List backups, restore a specific one and launch WebHare:
```bash
# Get a listing
runkit list-backups $CONTAINER
# Replace ARCHIVENAME with preferred archive
runkit restore-server --archive ARCHIVENAME $CONTAINER
# Install a proxy and WebHare (master branch) and start it
~/webhare-runkit/bin/startup-proxy-and-webhare.sh $CONTAINER
# Open a shell inside the WebHare container
~/webhare-runkit/bin/enter-webhare.sh $CONTAINER
```

Things you can do inside the container
```bash
# Get your bearings, verify WEBHARE_ISRESTORED is set
wh dirs
# Add a backened interface by IP. Look up the right IP address first. In chrome, bypass certwarning by typing "thisisunsafe"
wh webserver --addbackend https://159.223.25.195/
# Get an override token to use with the backend - keep in mind that you need to append the override token to an URL such as above
wh cli getoverride "Verifying restored server"
```

### Restoring a backup for development (OSX)
Eg. to locally debug an issue with a server. This assumes you have runkit and WebHare's source tree installed. In the
example the container is still named `demo` and the `demo.borg` credentials file is present

You can add `--nodocker` to `restore-server` and `launch-webhare.sh` to use your local WebHare source tree instead
of docker containers. This will generally be faster if you've built a compatible version of WebHare for the data you're restoring.

You can add the `--fast` option to `restore-server` to skip the restoration of logs and output.

You can redo database extraction (sometimes useful when testing) with `--skipdownload` if you've succesfully downloaded the backup earlier

```bash
CONTAINER=demo
~/webhare-runkit/bin/restore-server $CONTAINER
runkit-reload
wh-$CONTAINER console
```

### Troubleshooting
If borg gives you such as `argument REPOSITORY_OR_ARCHIVE: Invalid location format: ""`
you need to `open-backup.sh` on the server first. This sets some environment
variables that tell borg how to access the backup data.

To watch the logs for a running WebHare: `~/webhare-runkit/bin/watch-webhare.sh $CONTAINER`

Keep in mind that if you run all this on a mac, WebHare's database will be running
over a Docker volume mount and eg. index reconstruction after the restore can take
quite some time, especially if this installation isn't using postgres yet.

## Managing local WebHare installations
This guide assumes you've added `runkit` to your path or let setupmyshell set up
an alias

- `runkit ...`


## NOTES
- if you keep this WebHare running you'll want to remove 'whdata/preparedbackup' and `download` as they only take up space
