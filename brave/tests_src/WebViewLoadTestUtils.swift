/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation
import XCTest
@testable import Client
import Shared

class WebViewLoadTestUtils {
    static func urlProtocolEnabled(enable:Bool) {
        if enable {
          NSURLProtocol.registerClass(URLProtocol);
        } else {
          NSURLProtocol.unregisterClass(URLProtocol);
        }
    }

    static func httpseEnabled(enable: Bool) {
        URLProtocol.testShieldState = BraveShieldState()
        URLProtocol.testShieldState?.setState(BraveShieldState.kHTTPSE, on: enable)
    }

    static func loadSite(testCase: XCTestCase, site:String, webview:BraveWebView) ->Bool {
        let url = NSURL(string: "http://" + site)
        testCase.expectationForNotification(BraveWebViewConstants.kNotificationWebViewLoadCompleteOrFailed, object: nil, handler:nil)
        webview.loadRequest(NSURLRequest(URL: url!))
        var isOk = true
        testCase.waitForExpectationsWithTimeout(15) { (error:NSError?) -> Void in
            if let _ = error {
                isOk = false
            }
        }

        webview.stopLoading()
        testCase.expectationForNotification(BraveWebViewConstants.kNotificationWebViewLoadCompleteOrFailed, object: nil, handler:nil)
        webview.loadHTMLString("<html><head></head><body></body></html>", baseURL: nil)
        testCase.waitForExpectationsWithTimeout(2, handler: nil)

        return isOk
    }


    static func loadSites(testCase: XCTestCase, sites:[String]) {
        let w = BraveWebView(frame: CGRectMake(0,0,200,200))
        for site in sites {
            print("\(site)")
            self.loadSite(testCase, site: site, webview: w)
        }
    }
}