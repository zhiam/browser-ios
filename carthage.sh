#!/usr/bin/env sh
if which carthage ==/dev/null ; then
	brew update
	brew install carthage
fi
ver=`carthage version | sed -E 's/([0-9]\.[0-9]+)\.[0-9]$/\1/'`
ok=`echo "$ver > 0.17" | bc`
[[ $ok == 1 ]] || (echo "carthage needs upgrading"; brew upgrade carthage)
