#!/usr/bin/env sh
if which carthage ==/dev/null ; then
	brew update
	brew install carthage
fi
ver=`carthage version`
ok=`echo "$ver > 0.17" | bc`
[[ $ok == 1 ]] || (echo "carthage needs upgrading"; brew upgrade carthage)
