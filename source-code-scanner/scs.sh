#!/bin/bash
#Coded by @lemosnlmb

RED='\033[1;31m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

#Usage
printusage(){
    echo -e "${CYAN} ${BOLD}"
    echo -e "Example Usage: ${NC}"
    echo -e "./scs -l targets.txt"
    exit
}


while [ -n "$1" ]; do
    case $1 in
            -l|-list|--list)
                list=$2
                shift ;;

             *) echo -e "${RED} ${BOLD}"
                echo -e "Invalid Flag: $1"
		printusage
		exit
                shift ;;
    esac
    shift
done


if [ ! -n "$list" ]; then
	echo -e "${RED}"
	echo -e "URL's list not supplied"
	printusage
	exit
fi


echo -e "${BOLD}${PURPLE}Scanning for exposed git folders (1/4)${NC}"
for targetna in $(cat $list); do
	if [[ $(curl -s -m 3 -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0" "${targetna}/.git/" -w %{http_code} -o /dev/null ) =~ '403' ]]; then
		echo -e "${BOLD}${YELLOW}[+] MAYBE VULN: ${NC}${targetna}"
	fi


	if [[ $(curl --connect-timeout 3 --max-time 3 -kLs "${targetna}/.git/" ) =~ 'Index of' ]]; then
		echo -e "${BOLD}${RED}[+] VULN: ${NC}${targetna}"
	fi
done

echo ""
echo -e "${BOLD}${PURPLE}Scanning for exposed Bazaar folders (2/4)${NC}"
for targetna in $(cat $list); do
	if [[ $(curl -s -m 3 -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0" "${targetna}/.bzr/" -w %{http_code} -o /dev/null ) =~ '403' ]]; then
		echo -e "${BOLD}${YELLOW}[+] MAYBE VULN: ${NC}${targetna}"
	fi


	if [[ $(curl --connect-timeout 3 --max-time 3 -kLs "${targetna}/.bzr/" ) =~ 'Index of' ]]; then
		echo -e "${BOLD}${RED}[+] VULN: ${NC}${targetna}"
	fi
done


echo ""
echo -e "${BOLD}${PURPLE}Scanning for exposed Mercury folders (3/4)${NC}"
for targetna in $(cat $list); do
	if [[ $(curl -s -m 3 -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0" "${targetna}/.hg/hgrc/" -w %{http_code} -o /dev/null ) =~ '403' ]]; then
		echo -e "${BOLD}${YELLOW}[+] MAYBE VULN: ${NC}${targetna}"
	fi


	if [[ $(curl --connect-timeout 3 --max-time 3 -kLs "${targetna}/.hg/hgrc/" ) =~ '[paths]' ]]; then
		echo -e "${BOLD}${RED}[+] VULN: ${NC}${targetna}"
	fi
done


echo ""
echo -e "${BOLD}${PURPLE}Scanning for exposed svn folders (4/4)${NC}"
for targetna in $(cat $list); do
	if [[ $(curl -s -m 3 -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0" "${targetna}/.svn/" -w %{http_code} -o /dev/null ) =~ '403' ]]; then
		echo -e "${BOLD}${YELLOW}[+] MAYBE VULN: ${NC}${targetna}"
	fi


	if [[ $(curl --connect-timeout 3 --max-time 3 -kLs "${targetna}/.svn/" ) =~ 'Index of' ]]; then
		echo -e "${BOLD}${RED}[+] VULN: ${NC}${targetna}"
	fi
done
