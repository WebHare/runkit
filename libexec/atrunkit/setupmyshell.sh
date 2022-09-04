#!/bin/bash
if [ -t 1 ]; then
  # If you want to see the output, `runkit setupmyshell | cat`
  echo "\`runkit setupmyshell\` should be invoked as: eval \$(\"$WHRUNKIT_ORIGCOMMAND\" setupmyshell)" 1>&2
  exit 1
fi

cat << HERE

runkit() { "$WHRUNKIT_ORIGCOMMAND" "\$@"; } ;
export -f runkit ;

runkit-reload() { eval \$("$WHRUNKIT_ORIGCOMMAND" setupmyshell) ; } ;
export -f runkit-reload ;

wh() { "$WHRUNKIT_ORIGCOMMAND" "@default" wh "\$@" ; } ;
export -f wh ;
whcd() {
  local DEST;
  DEST="\`wh run mod::system/scripts/internal/cli/getdir.whscr "\$@"\`";
  [ -n "\$DEST" ] && cd "\$DEST";
} ;
export -f whcd ;

complete -o filenames -o nospace -C 'wh __autocomplete_whcd' whcd ;
complete -o default -C 'wh __autocomplete_wh' wh ;

HERE

# TODO unregister wh- aliases for servers since removed? but this may for now be annoying for users who manually set up wh-xxx aliasses..
if [ -d "$WHRUNKIT_DATADIR" ]; then
  for SERVER in $( cd "$WHRUNKIT_DATADIR" ||exit 1; echo * ); do
    if [ -f "$WHRUNKIT_DATADIR/$SERVER/baseport" ]; then # it appears to be a usable installation...
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
fi
