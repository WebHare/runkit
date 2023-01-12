#!/bin/bash

IP="$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | tr -d '"')"
echo "$IP"
[ -n "$IP" ] && exit 0
exit 1
