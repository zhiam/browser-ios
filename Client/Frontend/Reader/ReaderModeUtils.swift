/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReaderModeUtils {

    static let DomainPrefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    static func simplifyDomain(domain: String) -> String {
        for prefix in DomainPrefixesToSimplify {
            if domain.hasPrefix(prefix) {
                return domain.substringFromIndex(domain.startIndex.advancedBy(prefix.characters.count))
            }
        }
        return domain
    }

    static func generateReaderContent(readabilityResult: ReadabilityResult, initialStyle: ReaderModeStyle) -> String? {
        guard let tmplPath = NSBundle.mainBundle().pathForResource("Reader", ofType: "html") else { return nil }

        do {
            let tmpl = try NSMutableString(contentsOfFile: tmplPath, encoding: NSUTF8StringEncoding)

            let replacements: [String: String] = ["%READER-STYLE%": initialStyle.encode(),
                                                  "%READER-DOMAIN%": simplifyDomain(readabilityResult.domain),
                                                  "%READER-URL%": readabilityResult.url,
                                                  "%READER-TITLE%": readabilityResult.title,
                                                  "%READER-CREDITS%": readabilityResult.credits,
                                                  "%READER-CONTENT%": readabilityResult.content
            ]

            for (k,v) in replacements {
                tmpl.replaceOccurrencesOfString(k, withString: v, options: NSStringCompareOptions(), range: NSMakeRange(0, tmpl.length))
            }

            return tmpl as String
        } catch _ {
            return nil
        }
    }

    static func isReaderModeURL(url: NSURL) -> Bool {
        let scheme = url.scheme, host = url.host, path = url.path
        return scheme == "http" && host == "localhost" && path == "/reader-mode/page"
    }

    static func decodeURL(url: NSURL) -> NSURL? {
        if ReaderModeUtils.isReaderModeURL(url) {
            if let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false), queryItems = components.queryItems where queryItems.count == 1 {
                if let queryItem = queryItems.first, value = queryItem.value {
                    return NSURL(string: value)
                }
            }
        }
        return nil
    }

    static func encodeURL(url: NSURL?) -> NSURL? {
        let baseReaderModeURL: String = WebServer.sharedInstance.URLForResource("page", module: "reader-mode")
        if let absoluteString = url?.absoluteString {
            if let encodedURL = absoluteString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) {
                if let aboutReaderURL = NSURL(string: "\(baseReaderModeURL)?url=\(encodedURL)") {
                    return aboutReaderURL
                }
            }
        }
        return nil
    }
}
