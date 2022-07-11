# Source Code Scanner (SCS)

Source Code Scanner (SCS) is a bash script that scans for exposed Git, Bazaar, Mercurial and Subversion folders by providing a list of URL's.

Inspired tweet: 
<blockquote class="twitter-tweet"><p>We can now embed Public Facebook Posts on websites.&#10;&#10;<a href="http://t.co/Bmqpq3GgSB">http://t.co/Bmqpq3GgSB</a></p>&mdash; Andrea DeMers (@ademers) <a href="https://twitter.com/ademers/statuses/370530357390888960">August 22, 2013</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

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




