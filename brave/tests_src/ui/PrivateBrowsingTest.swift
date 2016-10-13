    /* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class PrivateBrowsingTest: XCTestCase {

    func pasteTextFieldText(app:XCUIApplication, element:XCUIElement, value:String, clearText:Bool) {
        UIPasteboard.generalPasteboard().string = value
        element.tap()
        app.menuItems["Paste"].tap()
    }

    func testPrivateBrowsing() {
        UITestUtils.restart()
        let app = XCUIApplication()

        let uuid = NSUUID().UUIDString
        let searchString = "foo\(uuid.substringToIndex(uuid.startIndex.advancedBy(5)))"

        app.buttons["Toolbar.ShowTabs"].tap()

        let privModeButton = app.buttons["TabTrayController.togglePrivateMode"]
        privModeButton.tap()
        sleep(1)
        XCTAssert(privModeButton.selected)
        privModeButton.tap()
        sleep(1)
        XCTAssert(!privModeButton.selected)

        privModeButton.tap()
        sleep(1)
        if !privModeButton.selected {
            privModeButton.tap()
            sleep(1)
        }

        XCTAssert(privModeButton.selected)

        app.buttons["TabTrayController.addTabButton"].tap()
        
        app.collectionViews["Top Sites View"].cells["google"].tap()

        let googleSearchField = app.otherElements["Web content"].otherElements["Search"]
        googleSearchField.tap()
        pasteTextFieldText(app, element: googleSearchField, value: "\(searchString)\r", clearText: false)

        app.otherElements["Web content"].buttons["Google Search"].tap()

        app.buttons["Toolbar.ShowTabs"].tap()

        privModeButton.tap() // off

        sleep(1)
        app.otherElements["Tabs Tray"].collectionViews.cells.elementBoundByIndex(0).tap()

        let topSitesViewCollectionView = app.collectionViews["Top Sites View"]
        topSitesViewCollectionView.cells["google"].tap()

        googleSearchField.tap()

        XCTAssert(!app.otherElements["\(searchString) ×"].exists)
        let predicate = NSPredicate(format: "label BEGINSWITH[cd] '\(searchString)'")
        XCTAssert(!app.otherElements.elementMatchingPredicate(predicate).exists)
    }
}
