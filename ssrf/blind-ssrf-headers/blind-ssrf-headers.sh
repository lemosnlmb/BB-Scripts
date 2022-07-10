#!/bin/bash
#Coded by @lemosnlmb

#Colors
RED='\033[1;31m'
NC='\033[0m'

list=$1
server=$2

#Taking out http(s) protocol scheme from server URL
server_fix=$(echo $server | sed -r "s/https?:\/\///")

echo -e "${RED}CHECK YOUR SERVER FOR POTENTIALS CALLBACKS!${NC}"
ffuf -r -w $list:W1,headers.txt:W2 -H "W2: $server_fix" -u W1 2 > /dev/null
