/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}



extension String {
    func regexReplacePattern(pattern:String,  with:String) -> String {
        let regex = try! NSRegularExpression(pattern:pattern, options: [])
        return regex.stringByReplacingMatchesInString(self, options: [], range: NSMakeRange(0, self.characters.count), withTemplate: with)
    }
}

extension NSURL {
    func hostWithGenericSubdomainPrefixRemoved() -> String? {
        return host != nil ? stripGenericSubdomainPrefixFromUrl(host!) : nil
    }
}

// Firefox has uses urls of the form  http://localhost:6571/errors/error.html?url=http%3A//news.google.ca/ to populate the browser history, and load+redirect using GCDWebServer
func stripLocalhostWebServer(url: String) -> String {
#if !TEST // TODO fix up the fact lots of code isn't available in the test suite, this is just an additional check, so for testing the rest of the code will work fine
    if !url.startsWith(WebServer.sharedInstance.base) {
        return url
    }
#endif
    // I think the ones prefixed with the following are the only ones of concern. There is also about/sessionrestore urls, not sure if we need to look at those
    let token = "errors/error.html?url="
    let range = url.rangeOfString(token)
    if let range = range {
        return url.substringFromIndex(range.endIndex)
    } else {
        return url
    }
}

func stripGenericSubdomainPrefixFromUrl(url: String) -> String {
    return url.regexReplacePattern("^(m\\.|www\\.|mobile\\.)", with:"");
}
