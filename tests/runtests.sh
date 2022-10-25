#!/bin/bash

cd "${BASH_SOURCE%/*}"
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
