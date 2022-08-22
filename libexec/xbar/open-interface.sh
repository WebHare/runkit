#!/bin/bash

open "$( "${BASH_SOURCE%/*}/../../bin/runkit" "@$1" wh get primarywebhareinterfaceurl )"


