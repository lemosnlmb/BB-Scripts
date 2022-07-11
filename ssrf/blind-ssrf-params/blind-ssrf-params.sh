#!/bin/bash
#Coded by @lemosnlmb

#Colors
RED='\033[1;31m'
NC='\033[0m'

list=$1
server=$2

cat $list | grep "=" | qsreplace "$server" 2>/dev/null | sort -u > $list.tmp
sed -i "s|$|\&dest=$server\&redirect=$server\&uri=$server\&path=$server\&continue=$server\&url=$server\&window=$server\&next=$server\&data=$server\&reference=$server\&site=$server\&html=$server\&val=$server\&validate=$server\&domain=$server\&callback=$server\&return=$server\&page=$server\&feed=$server\&host=$server&\port=$server\&to=$server\&out=$server\&view=$server\&dir=$server\&show=$server\&navigation=$server\&open=$server|g" $list.tmp
echo -e "${RED}CHECK YOUR SERVER FOR POTENTIALS CALLBACKS!${NC}"
ffuf -r -w $list.tmp -u FUZZ 2 > /dev/null

rm -rf $list.tmp
