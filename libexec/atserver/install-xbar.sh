#!/bin/bash
# syntax: <server>
# short: install an xbar plugin to manage the server

[ -d /Applications/xbar.app ] || ( echo "Installing xbar (using brew)" ; brew install xbar ; open /Applications/xbar.app )

PLUGINDIR="$HOME/Library/Application Support/xbar/plugins"
mkdir -p "$PLUGINDIR"
PLUGINBASE="$PLUGINDIR/runkit-$WHRUNKIT_TARGETSERVER"

# Delete any old versions (with different timings?)
rm -f -- "${PLUGINBASE}".*.sh
PLUGIN="$PLUGINBASE".5s.sh

cat > "$PLUGIN" << HERE
#!/bin/bash
"$WHRUNKIT_ROOT/libexec/xbar/plugin.sh" "$WHRUNKIT_TARGETSERVER"
HERE
chmod a+x "$PLUGIN"

open 'xbar://app.xbarapp.com/refreshAllPlugins'
