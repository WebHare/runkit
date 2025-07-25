#!/bin/bash
# command: __autocomplete ....
# short: Autocomplete runkit commands

source "${BASH_SOURCE%/*}/../runkit-functions.sh"

complete_installations()
{
  local completions i value
  completions=()
  IFS=$'\n' read -r -d '' -a completions < <(compgen -d "$WHRUNKIT_DATADIR/${1#@}")
  for i in "${completions[@]}"
  do
    value="${i#"$WHRUNKIT_DATADIR/"}"
    if [ -n "$value" ] && ! [[ $value == _* ]]; then
      COMPREPLY+=("@$value")
    fi
  done
  COMPREPLY+=("@default")
}

complete_command()
{
  local completions i value
  completions=()
  COMMAND_DIR="$1"
  IFS=$'\n' read -r -d '' -a completions < <(compgen -f "$COMMAND_DIR$2")
  for i in "${completions[@]}"
  do
    value="${i#"$COMMAND_DIR"}"
    value="${value%.sh}"
    if [ -n "$value" ] && ! [[ $value == _* ]]; then
      COMPREPLY+=("$value")
    fi
  done
}


autocomplete_init_compwords
if [ "$COMP_CWORD" == 1 ]; then
  complete_installations "${COMP_WORDS[$COMP_CWORD]}"
  complete_command "${BASH_SOURCE%/*}/../atrunkit/" "${COMP_WORDS[$COMP_CWORD]}"
elif [ "$COMP_CWORD" == 2 ] && [[ "${COMP_WORDS[1]}" == @* ]]; then
  # FIXME: it looks like container installations don't have the same commands, check for that
  complete_command "${BASH_SOURCE%/*}/../atserver/" "${COMP_WORDS[$COMP_CWORD]}"
elif [ "$COMP_CWORD" -gt 2 ] && [[ "${COMP_WORDS[1]}" == @* ]] && [ "${COMP_WORDS[2]}" == "wh" ]; then
  # FIXME: it looks like container installations don't have the same commands, check for that

  wh_params=("${COMP_WORDS[@]:2}")
  COMP_LINE="${wh_params[*]}" COMP_POINT="" "$WHRUNKIT_ORIGCOMMAND" "${COMP_WORDS[1]}" wh __autocomplete_wh
  exit 0
fi

autocomplete_print_compreply
