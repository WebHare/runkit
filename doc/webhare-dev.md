# Developing WebHare

## Getting the supporting code
```bash
# This will download and install the additional modules to your $HOME/projects directory
runkit download-support-source
```

### Checking out an additional source tree
This is used to eg manually verify a bootstrap-test (eg. whether you can still compile a bare source tree)

```bash
runkit download-webhare-source ~/projects/webhare-bootstrap-test
runkit create-server --source ~/projects/webhare-bootstrap-test bootstrap-test
runkit-reload
```

You can then try eg `runkit @webhare-bootstrap-test wh mic`

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

## Project links
`download-support-source` sets up links to the supporting projects so you can access them using `whcd`

If you have other git projects that you want to manage using `whcd`, `wh up`, `wh st`
etcetera, you should add them using `runkit link-project`. Eg `runkit link-project ~/projects/webhare-language-vscode/`
