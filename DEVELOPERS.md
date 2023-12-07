# runkit principles
(TODO: this part is for 'developers of runkit' and the above is for 'developers of WebHare'. split docs?)

- The WebHare-runkit and the embedded `wh` commands should avoid overlap as much as possible. `runkit` should invoke `wh` where
needed
- `wh` should limit itself to things that will also work inside the docker containers
  - so `wh` should not have the ability to install and start an OpenSearch dashboard - that's something we don't want to do
    inside containers but is fine on a source checkout
  - in time, `wh up` and `wh make` might turn out to be out-of-scope?


## repo layout
- `libexec/atinstall/<cmd>.sh` - commands that can be targeted at a server

## disk layout
runkit builds up a configuration data structure in `$WHRUNKIT_DATADIR`. every server gets a directory here, and runkit
local settings are stored in `$WHRUNKIT_DATADIR/_settings/`

- `<server>/` - configuration and state for an server
  - `borgsettings` - settings to access the Borg backup
  - `dataroot` - contains path to this server's data
  - `sourceroot` - contains path to the server's source code
  - `baseport` - port number
  - `opensearch-bindhost` - IP address to set as WEBHARE_OPENSEARCH_BINDHOST
  - `environment.sh` - if present and executable, this will be sourced just before executing the command. Use this to setup eg. `export WEBHARE_CI=1`
  - `startup.sh` - if present and executable, this will be setup as the WEBHARE_POSTSTARTSCRIPT
  - `container.image` - image to use for the WebHare server. if set, will be started using podman
- `_settings/`
  - getborgsettings.sh - a script to override how borg-related scripts lookup containers
  - containerchange.sh - if it exists, a script that is invoked whenever a container is started or stopped
  - `sourceroot` - contains default source checkout
  - `forgeroot` - overrides location of WebHare open source projects
  - `letsencryptemail` - email address for automatic letsencrypt accounts (and future eg. chtatplane proxy use?)
  - `publichostname` - used as WEBHAREPROXY_ADMINHOSTNAME, hosts a control interface for the proxy (and future eg. chtatplane proxy use? or usable by webhare to tell where its being hosted?)
- `_proxy/`
  - `container.image` - image to use for the proxy server

## credential files
Credential files (borgsettings) should have the following structure:

```bash
BORG_PRIVATEKEY="-----BEGIN OPENSSH PRIVATE KEY-----
....key data....
-----END OPENSSH PRIVATE KEY-----"
BORG_REPO="user@host.repo.borgbase.com:repo"
BORG_PASSPHRASE="key passphrase"
```

## runkit guidelines
- Do not invoke `wh` directly on a server. Use `$WHRUNKIT_WHCOMMAND` (setup by the `runkit @...` wrapper)


## "Remote" development
To simplify development you can quickly push local changes to eg a local VM using `runkit copy-runkit-to-server <user@host>`

### Using Vagrant
Prep if you're using Parallels, adapt if needed:

```bash
brew install hashicorp/tap/hashicorp-vagrant
vagrant plugin install vagrant-parallels
cd ~/projects/webhare-runkit
vagrant up

# Tests

```


## Build docker and restore

This recipe builds a local WebHare docker and restore a server into it

```bash
RESTORESERVER=demo # set to your container. make sure you have the .borg settings!
wh builddocker
runkit list-backups $RESTORESERVER
runkit restore-server $RESTORESERVER
bin/startup-proxy-and-webhare.sh $RESTORESERVER
```

