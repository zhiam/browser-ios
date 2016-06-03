[[ $1 == 'beta' ]] && bundle='com.brave.ios.browser.dev'
(cd .. && ./setup.sh $bundle)
(cd profiles && sh install-profiles-from-portal.sh $1) || exit 1 
sh strip-arch.sh
(cd -- "$(dirname -- "$0")" && cd ../.. && \
 xcodebuild archive -scheme Brave CODE_SIGN_IDENTITY="iPhone Distribution: Brave Software, Inc. (KL8N8XSYF4)")
