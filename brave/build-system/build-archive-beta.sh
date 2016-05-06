(cd ../../ && ./checkout.sh)
(cd .. && ./setup.sh com.brave.ios.browser.dev)
(cd profiles && sh install-profiles-from-portal.sh beta) || exit 1 

(cd -- "$(dirname -- "$0")" && cd ../.. && \
 xcodebuild archive -scheme Brave CODE_SIGN_IDENTITY="iOS Development: Brave Dev (KL8N8XSYF4)")
