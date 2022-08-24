#!/bin/bash

# https://github.com/matryer/xbar
# https://github.com/matryer/xbar-plugins/blob/main/CONTRIBUTING.md

echo "🐰 $1"
echo ---
echo "Open webinterface | shell='${BASH_SOURCE%/*}/open-interface.sh' param1='$1' terminal=false"
echo "OpenSearch dashboard | shell='${BASH_SOURCE%/*}/../../bin/runkit' param1='@$1' param2='opensearch-dashboard' terminal=true"
