/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class WebViewTest: XCTestCase {

    func testLongPress() {
        UITestUtils.restart()
        let app = XCUIApplication()
        UITestUtils.loadSite(app, "www.google.com")

        app.staticTexts["IMAGES"].pressForDuration(1.5);
        app.sheets.elementBoundByIndex(0).buttons["Open In New Tab"].tap()
        app.buttons["2"].tap()
        app.collectionViews.childrenMatchingType(.Cell).matchingIdentifier("Google").elementBoundByIndex(1).tap()
    }

    func testLongPressAndCopyUrl() {
        UITestUtils.restart()
        let app = XCUIApplication()
        UITestUtils.loadSite(app, "www.google.com")

        app.staticTexts["IMAGES"].pressForDuration(1.5);

        UIPasteboard.generalPasteboard().string = ""
        app.sheets.elementBoundByIndex(0).buttons["Copy Link"].tap()
        let string = UIPasteboard.generalPasteboard().string
        XCTAssert(string != nil && string!.containsString("output=search"), "copy url context menu failed")
    }

    func testShowDesktopSite() {
        UITestUtils.restart()
        let app = XCUIApplication()
        UITestUtils.loadSite(app, "www.whatsmyua.com")

        var search = NSPredicate(format: "label contains[c] %@", "CPU iPhone")
        var found = app.staticTexts.elementMatchingPredicate(search)
        XCTAssert(found.exists, "didn't find UA for iPhone")

        app.buttons["BrowserToolbar.shareButton"].tap()
        app.collectionViews.collectionViews.buttons["Open Desktop Site tab"].tap()

        sleep(1)
        search = NSPredicate(format: "label contains[c] %@", "Intel Mac")
        found = app.staticTexts.elementMatchingPredicate(search)
        XCTAssert(found.exists, "didn't find UA for desktop")
    }
}
