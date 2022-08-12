#!/bin/bash

#TODO reuse or merge with wh shell?
PS1="[$WHRUNKIT_TARGETSERVER \W]\$ "
export PS1
exec $SHELL
