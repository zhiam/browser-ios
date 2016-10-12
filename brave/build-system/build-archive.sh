[[ $1 == 'release' ]] && bundle='com.brave.ios.browser'
[[ $1 == 'beta' ]] && bundle='com.brave.ios.browser.dev'
(cd .. && ./setup.sh $bundle)
sh strip-arch.sh
(cd -- "$(dirname -- "$0")" && cd ../.. && \
 xcodebuild archive -scheme Brave )
