// Handy util: pass in PR number to apply patch
{ 
cd $(dirname $0)
wget -O /tmp/p.diff https://github.com/brave/browser-ios/pull/$1.diff
cd ..
patch -p1 < /tmp/p.diff
}
