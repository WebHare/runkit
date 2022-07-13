#!/bin/bash
if [ -t 1 ]; then
  echo "\`runkit setupmyshell\` should be invoked as: eval \$(\"$WHRUNKIT_ORIGCOMMAND\" setupmyshell)" 1>&2
  exit 1
fi

# TODO unregister wh- aliases for servers since removed? but this may for now be annoying for users who manually set up wh-xxx aliasses..

for SERVER in $( cd "$WHRUNKIT_ROOT/local" ||exit 1; echo * ); do
  if [ -f "$WHRUNKIT_ROOT/local/$SERVER/dataroot" ]; then # it appears to be a usable insatllation...
    echo "wh-$SERVER() { \"$WHRUNKIT_ORIGCOMMAND\" \"@$SERVER\" wh \"\$@\" ; } ;"
  fi
done

cat << HERE

runkit() { "$WHRUNKIT_ORIGCOMMAND" "\$@"; } ;
runkit-reload() { eval \$("$WHRUNKIT_ORIGCOMMAND" setupmyshell) ; } ;

HERE
