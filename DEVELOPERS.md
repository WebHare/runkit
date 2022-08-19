# runkit principles
- The WebHare-runkit and the embedded `wh` commands should avoid overlap as much as possible. `runkit` should invoke `wh` where
needed
- `wh` should limit itself to things that will also work inside the docker containers
  - so `wh` should not have the ability to install and start an OpenSearch dashboard - that's something we don't want to do
    inside containers but is fine on a source checkout
  - in time, `wh up` and `wh make` might turn out to be out-of-scope?


## repo layout
- `libexec/atinstall/<cmd>.sh` - commands that can be targeted at a server

## disk layout
runkit builds up a configuration data structure in `$WHRUNKIT_DATAROOT`. every server gets a directory here, and runkit
local settings are stored in `$WHRUNKIT_DATAROOT/_settings/`

- `<server>/` - configuration and state for an server
  - `borgsettings` - settings to access the Borg backup
  - `dataroot` - contains path to this server's data
  - `baseport` - port number
  - `opensearch-bindhost` - IP address to set as WEBHARE_OPENSEARCH_BINDHOST
  - `environment.sh` - if present and executable, this will be sourced just before executing the command. Use this to setup eg. `export WEBHARE_CI=1`
  - `startup.sh` - if present and executable, this will be setup as the WEBHARE_POSTSTARTSCRIPT
- `_settings/`
  - getborgsettings.sh - a script to override how borg-related scripts lookup containers


## credential files
Credential files (borgsettings) should have the following structure:

```bash
BORG_PRIVATEKEY="-----BEGIN OPENSSH PRIVATE KEY-----
....key data....
-----END OPENSSH PRIVATE KEY-----"
BORG_REPO="user@host.repo.borgbase.com:repo"
BORG_PASSPHRASE="key passphrase"


# Tests

## Build docker and restore

This recipe builds a local WebHare docker and restore a server into it

```bash
RESTORESERVER=demo # set to your container. make sure you have the .borg settings!
wh builddocker
runkit list-backups $RESTORESERVER
runkit restore-server $RESTORESERVER
bin/startup-proxy-and-webhare.sh tp-webhare
````
