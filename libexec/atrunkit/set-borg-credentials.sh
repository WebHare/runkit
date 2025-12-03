#!/bin/bash
# syntax: <server>
# short: Install borg credentials for a server. Settings file should be sent over stdin

WHRUNKIT_TARGETSERVER="$1"
if [ -z "$WHRUNKIT_TARGETSERVER" ]; then
  echo "Syntax: runkit set-borg-settings <server>"
  exit 1
fi

set -e
validate_servername "$WHRUNKIT_TARGETSERVER"
loadtargetsettings

SETTINGSFILE="$(mktemp)"
cleanup()
{
  rm -f "$SETTINGSFILE"
}

trap cleanup EXIT

[ -t 0 ] && echo "Paste your borg settings below and press CTRL+D when done"
cat > $SETTINGSFILE

source $SETTINGSFILE
[ -n "$BORG_REPO" ] || die "Invalid or incomplete settings received"
[ -n "$BORG_PASSPHRASE" ] || die "Invalid or incomplete settings received"
[ -n "$BORG_PRIVATEKEY" ] || die "Invalid or incomplete settings received"

mkdir -p "$WHRUNKIT_TARGETDIR"
mv "$SETTINGSFILE" "$WHRUNKIT_TARGETDIR"/borgsettings.restore
exit 0
