private let _singleton = PrivateBrowsing()

class PrivateBrowsing {
    class var singleton: PrivateBrowsing {
        return _singleton
    }

    var isOn = false

    var nonprivateCookies = [NSHTTPCookie: Bool]()

    func enter() {
        NSURLCache.sharedURLCache().memoryCapacity = 0;
        NSURLCache.sharedURLCache().diskCapacity = 0;

        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        if let cookies = storage.cookies {
        for cookie in cookies {
                    nonprivateCookies[cookie] = true
                }
        }
    }

    func exit() {
        if !isOn {
            return
        }

        isOn = false

        BraveApp.setupCacheDefaults()

        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        if let cookies = storage.cookies {
            for cookie in cookies {
                if nonprivateCookies[cookie] == nil {
                    storage.deleteCookie(cookie)
                }
            }
        }

        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
