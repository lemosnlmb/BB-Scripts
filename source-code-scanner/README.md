# Source Code Scanner (SCS)

Source Code Scanner (SCS) is a script that scans for exposed git, Bazaar, Mercury and svn folders by providing a list of URL's.

### Usage

```sh
./scs.sh -h
```

```
Required Flag: 
   -l, --list                           Add URL's list to scan

Scan modes: 
   -g, --git                            Scan for exposed git folders
   -b, --bazaar                         Scan for exposed Bazaar folders
   -m, --mercury                        Scan for exposed Mercury folders
   -s, --svn                            Scan for exposed svn folders
   -a, --all                            Scan for all exposed folders

Examples: 
   ./scs.sh -l urls.txt -g -b -s        Scanning for git, Bazaar and svn folders
   ./scs.sh -l urls.txt -m              Scanning only for Mercury folders
   ./scs.sh -l urls.txt -a              Scanning for all folders
   ```

![image](https://user-images.githubusercontent.com/80685782/178124612-cd17a9b0-d8cb-4034-b7b5-9a9b1a95d49f.png)


