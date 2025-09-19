#!/bin/bash

# short: Returns shell configuration to enable `wh` and `whcd` commands

if [ -t 1 ]; then
  # If you want to see the output, `runkit setupmyshell | cat`
  echo "'runkit setupmyshell' should be invoked as: eval \$(\"$WHRUNKIT_ORIGCOMMAND\" setupmyshell)" 1>&2
  exit 1
fi

mkdir -p "$WHRUNKIT_DATADIR" # Prevents errors from scripts accessing this dir

#
# whcd() needs the [ "\${1%%/*}" != "\$1" ] check to make sure "whcd chatplane" works (otherwise it breaks on not seeing any slash '/')
#

cat << HERE

runkit() { "$WHRUNKIT_ORIGCOMMAND" "\$@"; } ;
export -f runkit ;

runkit-reload() { eval \$("$WHRUNKIT_ORIGCOMMAND" setupmyshell) ; } ;
export -f runkit-reload ;

wh() { WEBHARE_WHCOMMAND=wh "$WHRUNKIT_ORIGCOMMAND" "@default" wh "\$@" ; } ;
export -f wh ;
whcd() {
  local DEST;
  if [ -n "\$1" ] && [ -d "$WHRUNKIT_DATADIR/_settings/projectlinks/\${1%%/*}" ]; then
    DEST="\$(readlink "$WHRUNKIT_DATADIR/_settings/projectlinks/\${1%%/*}")/";
    [ "\${1%%/*}" != "\$1" ] && DEST="\${DEST}/\${1#*/}" ;
  elif [ -z "\$1" ]; then
    DEST="\$(wh getdatadir)";
  else
    DEST="\$(wh tofspath "mod::\$1")";
  fi ;
  [ -n "\$DEST" ] && cd "\$DEST";
} ;
export -f whcd ;

__autocomplete_default_whcd() {
  "$WHRUNKIT_ORIGCOMMAND" "@default" __autocomplete_whcd "$@" ;
} ;

complete -o filenames -o nospace -C '"$WHRUNKIT_ORIGCOMMAND" "@default" __autocomplete_whcd' whcd ;
complete -o default -o nospace -C 'wh __autocomplete_wh' wh ;
complete -o default -C '"$WHRUNKIT_ORIGCOMMAND" __autocomplete_runkit' runkit ;

HERE

# TODO unregister wh- aliases for servers since removed? but this may for now be annoying for users who manually set up wh-xxx aliasses..
for SERVER in $( cd "$WHRUNKIT_DATADIR" ||exit 1; echo * ); do
  if [ -f "$WHRUNKIT_DATADIR/$SERVER/baseport" ]; then # it appears to be a usable installation...
    cat << HERE
wh-$SERVER() { WEBHARE_WHCOMMAND="wh-$SERVER" "$WHRUNKIT_ORIGCOMMAND" "@$SERVER" wh "\$@" ; } ;
export -f wh-$SERVER ;
whcd-$SERVER() {
local DEST;
if [ -z "\$1" ]; then
  DEST="\$(wh-$SERVER getdatadir)";
else
  DEST="\`wh-$SERVER tofspath "mod::\$@"\`";
fi ;
[ -n "\$DEST" ] && cd "\$DEST";
} ;
export -f whcd-$SERVER ;

complete -o filenames -o nospace -C '"$WHRUNKIT_ORIGCOMMAND" "@$SERVER" __autocomplete_whcd' whcd-$SERVER ;
complete -o default -o nospace -C 'wh-$SERVER __autocomplete_wh' wh-$SERVER ;

HERE
  fi
done
