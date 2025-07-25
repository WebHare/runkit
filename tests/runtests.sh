#!/bin/bash

cd "${BASH_SOURCE%/*}/.." || exit 1

cd tests || exit 1
for P in ./test-*.sh ; do
  if ! $P ; then
    echo ""
    echo "** Test failed!"
    exit 1
  fi
done

echo ""
echo "** All tests succeeded"
exit 0
