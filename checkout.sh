#!/usr/bin/env sh

./carthage.sh

carthage checkout --platform ios --no-use-binaries --toolchain com.apple.dt.toolchain.Swift_2_3
