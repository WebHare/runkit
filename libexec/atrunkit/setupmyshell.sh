#!/bin/bash
if [ -t 1 ]; then
  echo "\`runkit setupmyshell\` should be invoked as: eval \$(\"$WHRUNKIT_ORIGCOMMAND\" setupmyshell)" 1>&2
  exit 1
fi

cat << HERE

runkit() { "$WHRUNKIT_ORIGCOMMAND" "\$@"; } ;
runkit-reload() { eval \$("$WHRUNKIT_ORIGCOMMAND" setupmyshell) ; } ;

HERE
