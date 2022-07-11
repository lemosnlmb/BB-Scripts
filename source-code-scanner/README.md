# Source Code Scanner (SCS)

Source Code Scanner (SCS) is a bash script that scans for exposed Git, Bazaar, Mercurial and Subversion folders by providing a list of URL's.

Inspired tweet: https://twitter.com/intigriti/status/1533050946212839424

### Usage

```sh
./scs.sh -h
```
This will display help for the tool. Here are all the switches it supports.

```
Required Flag: 
   -l, --list                           Add URL's list to scan

Scan modes: 
   -g, --git                            Scan for exposed Git folders
   -b, --bazaar                         Scan for exposed Bazaar folders
   -m, --mercurial                      Scan for exposed Mercurial folders
   -s, --subversion                     Scan for exposed Subversion folders
   -a, --all                            Scan for all exposed folders

Examples: 
   ./scs.sh -l urls.txt -g -b -s        Scanning for Git, Bazaar and Subversion folders
   ./scs.sh -l urls.txt -m              Scanning only for Mercurial folders
   ./scs.sh -l urls.txt -a              Scanning for all folders
   ```

![image](https://user-images.githubusercontent.com/80685782/178269188-d42f65a0-e1b8-45cf-a063-51616a554319.png)





