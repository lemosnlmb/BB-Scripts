#!/bin/bash
#Coded by @lemosnlmb

RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'

list=$1

ffuf -v -w $list:W1,headers.txt:W2,payloads.txt:W3 -H 'W2: W3' -u W1 -mr ".*uid=.*gid=.*" -s | while read url
do
	echo -e "${RED}Vulnerable to RCE${NC}: $url" |
	awk -v srch="W1 :" -v repl="${CYAN}URL${NC}->" '{ sub(srch,repl,$0); print $0 }' | awk -v srch="W2 :" -v repl="${CYAN}HEADER${NC}->" '{ sub(srch,repl,$0); print $0 }' | awk -v srch="W3 :" -v repl="${CYAN}PAYLOAD${NC}->" '{ sub(srch,repl,$0); print $0 }'
done
