#!/bin/bash
#Coded by @lemosnlmb

RED='\033[1;31m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

#Usage
printusage(){
    echo -e "${CYAN}"
    echo -e "Example Usage: ${NC}"
    echo -e "./scs -l targets.txt"
    exit
}


#Usage
printusage(){
    echo -e "${CYAN}"
    echo -e "Required Flag: ${NC}"
    echo -e "   -l, --list              		${YELLOW}Add URL's to scan${NC}"
    echo -e "${CYAN}"
    echo -e "Scan modes: ${NC}"
    echo -e "   -g, --git               		${YELLOW}Scan for exposed Git folders${NC}"
    echo -e "   -b, --bazaar            		${YELLOW}Scan for exposed Bazaar folders${NC}"
    echo -e "   -m, --mercurial           		${YELLOW}Scan for exposed Mercurial folders${NC}"
    echo -e "   -s, --subversion               	${YELLOW}Scan for exposed Subversion folders${NC}"
    echo -e "   -a, --all               		${YELLOW}Scan for all exposed folders${NC}"
    echo -e "${CYAN}"
    echo -e "Examples: ${NC}"
    echo -e "   ./scs.sh -l urls.txt -g -b -s        ${YELLOW}Scanning for Git, Bazaar and Subversion folders${NC}"
    echo -e "   ./scs.sh -l urls.txt -m              ${YELLOW}Scanning only for Mercury folders${NC}"
    echo -e "   ./scs.sh -l urls.txt -a              ${YELLOW}Scanning for all folders${NC}"
    exit
}


while [ -n "$1" ]; do
    case $1 in
            -l|-list|--list)
                list=$2
                shift 2
		continue ;;

	    -g|-git|--git)
		git=true
		shift
		continue ;;

	    -b|-bazaar|--bazaar)
		bazaar=true
		shift
		continue ;;

	    -m|-mercurial|--mercurial)
		mercurial=true
		shift
		continue ;;

	    -s|-subversion|--subversion)
		subversion=true
		shift
		continue ;;

	    -a|-all|--all)
		all=true
		shift
		continue ;;

	    -h|-help|--help)
            	printusage
           	shift ;;

             *) echo -e "${RED}"
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


if [ $git ] || [ $all ]; then
echo -e "${PURPLE}Scanning for exposed Git folders${NC}"
	for targetna in $(cat $list); do
		if [[ $(curl -s -m 3 -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0" "${targetna}/.git/" -w %{http_code} -o /dev/null ) =~ '403' ]]; then
			echo -e "${YELLOW}[+] MAYBE VULN: ${NC}${targetna}"
		fi

		if [[ $(curl --connect-timeout 3 --max-time 3 -kLs "${targetna}/.git/" ) =~ 'Index of' ]]; then
			echo -e "${RED}[+] VULN: ${NC}${targetna}"
		fi
	done
	echo ""
fi


if [ $bazaar ] || [ $all ]; then
echo -e "${PURPLE}Scanning for exposed Bazaar folders${NC}"
for targetna in $(cat $list); do
		if [[ $(curl -s -m 3 -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0" "${targetna}/.bzr/" -w %{http_code} -o /dev/null ) =~ '403' ]]; then
			echo -e "${YELLOW}[+] MAYBE VULN: ${NC}${targetna}"
		fi

		if [[ $(curl --connect-timeout 3 --max-time 3 -kLs "${targetna}/.bzr/" ) =~ 'Index of' ]]; then
			echo -e "${RED}[+] VULN: ${NC}${targetna}"
		fi
	done
echo ""
fi


if [ $mercurial ] || [ $all ]; then
echo -e "${PURPLE}Scanning for exposed Mercurial folders${NC}"
for targetna in $(cat $list); do
		if [[ $(curl -s -m 3 -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0" "${targetna}/.hg/hgrc/" -w %{http_code} -o /dev/null ) =~ '403' ]]; then
			echo -e "${YELLOW}[+] MAYBE VULN: ${NC}${targetna}"
		fi

		if [[ $(curl --connect-timeout 3 --max-time 3 -kLs "${targetna}/.hg/hgrc/" ) =~ '[paths]' ]]; then
			echo -e "${RED}[+] VULN: ${NC}${targetna}"
		fi
	done
echo ""
fi


if [ $subversion ] || [ $all ]; then
echo -e "${PURPLE}Scanning for exposed Subversion folders${NC}"
for targetna in $(cat $list); do
		if [[ $(curl -s -m 3 -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0" "${targetna}/.svn/" -w %{http_code} -o /dev/null ) =~ '403' ]]; then
			echo -e "${YELLOW}[+] MAYBE VULN: ${NC}${targetna}"
		fi

		if [[ $(curl --connect-timeout 3 --max-time 3 -kLs "${targetna}/.svn/" ) =~ 'Index of' ]]; then
			echo -e "${RED}[+] VULN: ${NC}${targetna}"
		fi
	done
echo ""
fi
