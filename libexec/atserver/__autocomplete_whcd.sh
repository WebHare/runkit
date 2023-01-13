#!/bin/bash
# command: __autocomplete_whcd ....
# short: Autocomplete whcd paths

source "${BASH_SOURCE%/*}/../runkit-functions.sh"

complete_with_prefix()
{
  local completions i subpath
  completions=()
  MODULE_PREFIX="$1"
  IFS=$'\n' read -r -d '' -a completions < <(compgen -d "$MODULE_PREFIX$2")
  for i in "${completions[@]}"
  do
    subpath="${i#"$MODULE_PREFIX"}"
    if [ -n "$subpath" ]; then
      COMPREPLY+=("$subpath/")
    fi
  done
}

COMPREPLY=()

autocomplete_init_compwords
if [ "$COMP_CWORD" == 1 ]; then
  complete_with_prefix "$WEBHARE_DATAROOT/node_modules/@mod-" "${COMP_WORDS[$COMP_CWORD]}"
  complete_with_prefix "$WHRUNKIT_DATADIR/_settings/projectlinks/" "${COMP_WORDS[$COMP_CWORD]}"
fi

if [ ${#COMPREPLY[@]} -eq 0 ]; then
  exec "$WHRUNKIT_WHCOMMAND" __autocomplete_whcd "$@"
else
  autocomplete_print_compreply
fi
