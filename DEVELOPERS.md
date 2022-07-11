# runkit principles
- The WebHare-runkit and the embedded `wh` commands should avoid overlap as much as possible. `runkit` should invoke `wh` where
needed
- `wh` should limit itself to things that will also work inside the docker containers
  - so `wh` should not have the ability to install and start an OpenSearch dashboard - that's something we don't want to do
    inside containers but is fine on a source checkout
  - in time, `wh up` and `wh make` might turn out to be out-of-scope?


# repo layout
- `libexec/atinstall/<cmd>.sh` - commands that can be targeted at a server

# disk layout
runkit builds up a configuration data structure in the `local` directory of its server. this directory is `.gitignore`d
to prevent accidental commits.

- `local/` - root of configuration data
  - `<server>.borg` - credentials and locations for borg backups (MAY BE DEPRECATED for consistency)
  - `local/state/<server>/` - state for the specific server (PARTIALLY DEPRECATED, stay tuned)
  - `<server>/` - configuration and state for an server
    - dataroot - contains path to this server's data
    - baseport - port number
    - `startup.sh` - if presentand executable,  this will be setup as the WEBHARE_POSTSTARTSCRIPT
