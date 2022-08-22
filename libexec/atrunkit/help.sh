#!/bin/bash
# short: Lists help for all commands

right_pad()
{
  PAD="                                       "
  if [ "${#1}" -gt "${#PAD}" ]; then
    PAD=""
  else
    PAD="${PAD:${#1}}"
  fi
  echo "$1$PAD"
}

show_commandfile_help() # instr filename
{
  local COMMAND SHORT
  COMMAND=$(grep -ie "^\(#\|///\?\) *command: " "$2")
  SHORT=$(grep -ie "^\(#\|///\?\) *short: " "$2")

  COMMAND=${COMMAND#*: }
  SHORT=${SHORT#*: }
  if [ -z "$SHORT" ]; then
    return
  fi

  if [ -z "$COMMAND" ]; then
    COMMAND="$1"
  fi
  echo "$(right_pad "$COMMAND") $SHORT"
}

echo "webhare-runkit: Manage and restore WebHare installations - https://gitlab.com/webhare/runkit"
echo ""

echo "* runkit global commands (runkit <cmd> ...)"
CMDS="$(cd "$WHRUNKIT_ROOT/libexec/atrunkit"; ls *.sh 2>/dev/null | sort )"
for CMD in $CMDS ; do
  SHOWCMD="$P${CMD%.sh}"
  SCRIPTPATH="$WHRUNKIT_ROOT/libexec/atrunkit/$P${CMD}"
  show_commandfile_help "$SHOWCMD" "$SCRIPTPATH"
done

echo ""
echo "* runkit server commands (runkit @<server> <cmd> ...)"
CMDS="$(cd "$WHRUNKIT_ROOT/libexec/atserver"; ls *.sh 2>/dev/null | sort )"
for CMD in $CMDS ; do
  SHOWCMD="$P${CMD%.sh}"
  SCRIPTPATH="$WHRUNKIT_ROOT/libexec/atserver/$P${CMD}"
  show_commandfile_help "$SHOWCMD" "$SCRIPTPATH"
done
