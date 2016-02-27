copy_framework ()
{
    local framework=$1

    local file_path="$framework/`basename $framework .framework`"

    lipo -remove i386 "$file_path" -output "$file_path"
    lipo -remove x86_64 "$file_path" -output "$file_path"
    
}

copy_framework ../../Carthage/Build/iOS/AdjustSdk.framework		
copy_framework ../../Carthage/Build/iOS/OnePasswordExtension.framework
copy_framework ../../Carthage/Build/iOS/Alamofire.framework		
copy_framework ../../Carthage/Build/iOS/SWXMLHash.framework
copy_framework ../../Carthage/Build/iOS/Base32.framework			
copy_framework ../../Carthage/Build/iOS/SnapKit.framework
copy_framework ../../Carthage/Build/iOS/Breakpad.framework		
copy_framework ../../Carthage/Build/iOS/SwiftKeychainWrapper.framework
copy_framework ../../Carthage/Build/iOS/Deferred.framework		
copy_framework ../../Carthage/Build/iOS/WebImage.framework
copy_framework ../../Carthage/Build/iOS/GCDWebServers.framework		
copy_framework ../../Carthage/Build/iOS/XCGLogger.framework
copy_framework ../../Carthage/Build/iOS/KIF.framework

