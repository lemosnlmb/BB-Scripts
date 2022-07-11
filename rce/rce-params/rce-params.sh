#!/bin/bash
#Coded by @lemosnlmb

#Colors
RED='\033[1;31m'
NC='\033[0m'

list=$1

cat $list | grep "=" | qsreplace "FUZZ" > $list.tmp && mv $list.tmp $list
interlace -tL $list.tmp -c "ffuf -v -r -w payloads.txt -u \"_target_\" -mr \".*uid=.*gid=.*\" " 2>/dev/null | grep "| URL |" | awk '{print $4}' | while read url
do 
  echo -e "${RED}Vulnerable to RCE${NC}: $url"
done

rm -rf $list.tmp
