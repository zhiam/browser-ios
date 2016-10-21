/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class WebViewTest: XCTestCase {

    func testLongPress() {
        UITestUtils.restart()
        let app = XCUIApplication()

        app.textFields["url"].tap()
        let topSitesViewCollectionView = app.collectionViews["Top Sites View"]
        topSitesViewCollectionView.cells["google"].tap()

        app.staticTexts["IMAGES"].pressForDuration(1.5);
        app.sheets.elementBoundByIndex(0).buttons["Open In New Tab"].tap()
        app.buttons["2"].tap()
        app.collectionViews.childrenMatchingType(.Cell).matchingIdentifier("Google").elementBoundByIndex(1).tap()
    }

    func testLongPressAndCopyUrl() {
        UITestUtils.restart()

        let app = XCUIApplication()
        app.textFields["url"].tap()
        let topSitesViewCollectionView = app.collectionViews["Top Sites View"]
        topSitesViewCollectionView.cells["google"].tap()
        app.staticTexts["IMAGES"].pressForDuration(1.5);

        UIPasteboard.generalPasteboard().string = ""
        app.sheets.elementBoundByIndex(0).buttons["Copy Link"].tap()
        let string = UIPasteboard.generalPasteboard().string
        XCTAssert(string != nil && string!.containsString("output=search"), "copy url context menu failed")
    }
}
