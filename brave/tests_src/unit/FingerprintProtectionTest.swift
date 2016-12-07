/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
@testable import Client
import Shared
import KIF

/*

 UITestUtils.loadSite(app, "panopticlick.eff.org")
 app.staticTexts["TEST ME"].tap()
 app.staticTexts["Show full results for fingerprinting"].tap()
 app.staticTexts["cb11ce1da2381e5f8a8add3145bd0da5"].tap()
 app.buttons["Brave Panel"].tap()
 */

class FingerprintProtectionTest: XCTestCase {
    static func enabled(enable: Bool) {
        URLProtocol.testShieldState = BraveShieldState()
        URLProtocol.testShieldState?.setState(.FpProtection, on: enable)
    }

    func testFingerprintProtection() {
        FingerprintProtectionTest.enabled(true)

        let url = NSURL(string: "https://panopticlick.eff.org/results")
        let webview = BraveApp.getCurrentWebView()
        webview!.loadRequest(NSURLRequest(URL: url!))


        expectationForNotification(BraveWebViewConstants.kNotificationWebViewLoadCompleteOrFailed, object: nil, handler:nil)

        waitForExpectationsWithTimeout(15) { (error:NSError?) -> Void in
            if let _ = error {
            }
        }

        var expect = expectationWithDescription("wait")
        postAsyncToMain(8) { expect.fulfill()}
        waitForExpectationsWithTimeout(10) { (error:NSError?) -> Void in }

        webview!.stringByEvaluatingJavaScriptFromString("document.getElementById('showFingerprintLink2').click();")
        expect = expectationWithDescription("wait")
        postAsyncToMain(3) { expect.fulfill() }
        waitForExpectationsWithTimeout(5) { (error:NSError?) -> Void in }


        let innerHtml = webview!.stringByEvaluatingJavaScriptFromString("document.body.innerHTML")
        XCTAssert(innerHtml != nil)
        XCTAssert(innerHtml!.contains("891f3debe00dbd3d1f0457a70d2f5213"))

        let match = webview!.stringByEvaluatingJavaScriptFromString("/webgl fingerprint.*(\\n.+)*undetermined/gim.exec(document.body.innerHTML)[0]")

        XCTAssert(match != nil && match?.characters.count > 50 && match?.characters.count < 300)
    }
}
