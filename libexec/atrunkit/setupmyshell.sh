#!/bin/bash
if [ -t 1 ]; then
  echo "\`runkit setupmyshell\` should be invoked as: eval \$(\"$WHRUNKIT_ORIGCOMMAND\" setupmyshell)" 1>&2
  exit 1
fi

# TODO unregister wh- aliases for servers since removed? but this may for now be annoying for users who manually set up wh-xxx aliasses..

for SERVER in $( cd "$WHRUNKIT_ROOT/local" ||exit 1; echo * ); do
  if [ -f "$WHRUNKIT_ROOT/local/$SERVER/dataroot" ]; then # it appears to be a usable insatllation...
    cat << HERE
wh-$SERVER() { "$WHRUNKIT_ORIGCOMMAND" "@$SERVER" wh "\$@" ; } ;
export -f wh-$SERVER ;
whcd-$SERVER() {
  local DEST;
  DEST="\`wh-$SERVER run mod::system/scripts/internal/cli/getdir.whscr "\$@"\`";
  [ -n "\$DEST" ] && cd "\$DEST";
} ;
export -f whcd-$SERVER ;

complete -o filenames -o nospace -C 'wh-$SERVER __autocomplete_whcd' whcd-$SERVER ;
complete -o default -C 'wh-$SERVER __autocomplete_wh' wh-$SERVER ;

HERE
  fi
done

cat << HERE

runkit() { "$WHRUNKIT_ORIGCOMMAND" "\$@"; } ;
export -f runkit ;

runkit-reload() { eval \$("$WHRUNKIT_ORIGCOMMAND" setupmyshell) ; } ;
export -f runkit-reload ;

HERE
