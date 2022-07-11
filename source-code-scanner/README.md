# Source Code Scanner (SCS)

Source Code Scanner (SCS) is a bash script that scans for exposed Git, Bazaar, Mercurial and Subversion folders by providing a list of URL's.

Inspired tweet: 
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">If checking for exposed source code is not in your methodology, then you may be missing out! 👁️‍🗨️<br><br>Let this hint by <a href="https://twitter.com/daffainfo?ref_src=twsrc%5Etfw">@daffainfo</a> help you out in that case, because exposed source code is a gold mine!<a href="https://twitter.com/hashtag/bugbounty?src=hash&amp;ref_src=twsrc%5Etfw">#bugbounty</a> <a href="https://twitter.com/hashtag/bugbountytips?src=hash&amp;ref_src=twsrc%5Etfw">#bugbountytips</a> 👇 <a href="https://t.co/NwdAwmGEgL">pic.twitter.com/NwdAwmGEgL</a></p>&mdash; INTIGRITI (@intigriti) <a href="https://twitter.com/intigriti/status/1533050946212839424?ref_src=twsrc%5Etfw">June 4, 2022</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

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

![image](https://user-images.githubusercontent.com/80685782/178268055-bcd1975e-c7b3-49db-9d52-f6d8f1b4187b.png)




