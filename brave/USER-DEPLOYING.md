# How to deploy the Brave iOS Browser on your own device

You will need:

- an [Apple Developer account](https://developer.apple.com) for iOS
- an [iOS certificate](https://developer.apple.com/account/ios/certificate/certificateList.action)
- to plug your device into your Mac
- to run these three commands:

    ./checkout.sh
    (cd brave; ./setup.sh com.bundle.app)
    open Client.xcodeproj
    and Run

The first time `Xcode` builds, 
you may see this dialog:

<img src='brave/docs/images/failed-to-sign.png' />

If so, please click `Fix Issue` and then click `Choose`.
If `Xcode` recovers,
then the build will complete successfully and you may now `Product > Run` (&#8984;R).

Going forward,
any time that you successfully sync with the repo,
please re-run the three shell commands above,
and then tell `Xcode` to `Product > Run` (&#8984;R).
