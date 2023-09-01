# WebHare runkit
Tools for running WebHare on desktops and servers and testing backup/restore procedures

Download this repository using either of
- `git clone git@gitlab.com:webhare/runkit.git webhare-runkit`
- `git clone https://gitlab.com/webhare/runkit.git webhare-runkit`

Or install it on your target machine by running `curl https://gitlab.com/webhare/runkit/-/raw/main/install.sh | bash` as root

To ease runkit use add `eval $(~/webhare-runkit/bin/runkit setupmyshell)` to your shell. You can then use `runkit-reload`
to reload the aliases without having to close your current session. You can also place just `runkit` in your path or invoke
it directly when invoking it. All examples below assume that `runkit` will invoke `bin/runkit` from this project.

We recommend adding `eval $(~/webhare-runkit/bin/runkit setupmyshell)` to your `~/.profile` or similar bash startup script

Runkit will store its data in `$HOME/whrunkit/` or `/opt/runkit-data/` by default. You can override this directory by setting
the WHRUNKIT_ROOT environment varaible

## Building WebHare from source
```bash
runkit get-webhare-source
runkit create-server --default mywebhare
runkit @mywebhare wh make
```

### Checking out an additional source tree
This is used to eg manually verify a bootstrap-test (eg. whether you can still compile a bare source tree)

```bash
runkit get-webhare-source ~/projects/webhare-bootstrap-test
runkit create-server --source ~/projects/webhare-bootstrap-test bootstrap-test
runkit-reload
```

You can then try eg `wh webhare-bootstrap-test mic`

## Managing WebHare installations
Before you can use runkit, you need to set up a new installation or add your existing installation:
- `add-existing-server [--default] <servername> <path>` - Add an already configured WebHare
- `create-server [--default] <servername>` - Set up a new installation with the given name

Examples:
```bash
# Sets up a new server (will be initialized by invoking 'runkit @mytest console')
runkit create-server mytest

# Adds ~/projects/whdata/myserver as your primary installation
runkit add-existing-server --default myserver ~/projects/whdata/myserver
```

The primary installation is the one with baseport '13679' and will be bound to the `wh` alias by runkit's setupmyshell.
Other installs are bound to a `wh-server` alias eg `wh-mytest`. You can always target a server using `runkit @<server> ...`.

## Setting up a discardable WebHare for CI tests
You can setup an installation for easily running CI tests on a 'fresh' WebHare install. There are many different ways to
set this up, as an example (edit as necessary)

```bash
# Create a WebHare server named 'ci'
runkit create-server ci
runkit-reload

# Setup environment and startup script to configure it
cd "$(runkit @ci getserverconfigdir)"
echo "export WEBHARE_CI=1" > environment.sh
cat << HERE > startup.sh
#!/bin/bash
if ! wh webserver addport 8888 2>/dev/null ; then
  echo "looks like startup script has already run"
  exit 0
fi

echo "Setting up for tests"
wh webserver addbackend --default http://localhost:8888/
wh webhare_testsuite:reset
wh users adduser --sysop --password secret sysop@example.net
wh registry set system.backend.layout.infotitle "CI login info"
wh registry set system.backend.layout.infotext "Login using username sysop@example.net and password secret"
exit 0
HERE

chmod a+x environment.sh startup.sh

mkdir -p "/$(wh-ci getdatadir)/etc"
touch "/$(wh-ci getdatadir)/etc/allow-fresh-db"

# To start your database fresh:
runkit @ci freshdbconsole
# And then in a second terminal you can already...
wh-ci runtest "consilio.*"

# Install some modules from your primary insatllation
ln -s "$(wh getmoduledir dev)" "$(wh-ci getdatadir)/installedmodules/"
```

### Using podman
runkit can be used to manage a podman-based server.

```bash
runkit install-proxy
```

## Restoring WebHare backups
We've built runkit restore around borg backup repositories. You need to supply runkit with the proper credentials to
access these backups. Request these credentials from whoever is hosting your backups. Either the 
`*borgbase.borg` or the `*rsync.borg` files can be used (if both available).

Paste these credentials into `runkit set-borg-credentials <server>` and test the credentials
by entering `runkit list-backups <server>`.

If you keep a restored WebHare running you'll want to remove 'whdata/preparedbackup' and `download` directories as they only
take up space once the restore is done

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
example the container is still named `demo` and the `demo.borg` credentials file is present.

Use `runkit restore-server` to create a new 'restored from backup' server (don't use `runkit create-server`). 
You can add `--nodocker` to `restore-server` and `launch-webhare.sh` to use your local WebHare source tree 
instead of docker containers. This will generally be faster if you've built a compatible version of WebHare for 
the data you're restoring.

You can add the `--fast` option to `restore-server` to skip the restoration of logs and output.

You can redo database extraction (sometimes useful when testing) with `--skipdownload` if you've succesfully downloaded the backup earlier

```bash
CONTAINER=demo
runkit restore-server $CONTAINER
runkit @$CONTAINER console
```

### Project links
If you have other git projects that you want to manage using `whcd`, `wh up`, `wh st`
etcetera, you should add them using `runkit link-project`. Eg `runkit link-project ~/projects/webhare-language-vscode/`

### Troubleshooting
If borg gives you such as `argument REPOSITORY_OR_ARCHIVE: Invalid location format: ""`
you need to `open-backup.sh` on the server first. This sets some environment
variables that tell borg how to access the backup data.

To watch the logs for a running WebHare: `~/webhare-runkit/bin/watch-webhare.sh $CONTAINER`

Keep in mind that if you run all this on a mac, WebHare's database will be running
over a Docker volume mount and eg. index reconstruction after the restore can take
quite some time, especially if this installation isn't using postgres yet.


