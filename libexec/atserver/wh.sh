#!/bin/bash

# FIXME how to find the source/code root ?

if [ -n "$WEBHARE_DIR" ] && [ -x "$WEBHARE_DIR/bin/wh" ]; then
  exec "$WEBHARE_DIR/bin/wh" "$@"
  exit 255
fi

if [ -x ~/projects/webhare/whtree/bin/wh ]; then
  exec ~/projects/webhare/whtree/bin/wh "$@"
  exit 255
fi

echo "Don't know where to find your bin/wh" 1>&2
exit 1
