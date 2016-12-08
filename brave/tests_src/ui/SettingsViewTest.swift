/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class SettingsViewTest : XCTestCase {
    func testReportABug() {
        UITestUtils.restart()
        let app = XCUIApplication()

        app.buttons["Bookmarks and History Panel"].tap()
        app.otherElements.buttons["Settings"].tap()
        let table = app.tables["AppSettingsTableViewController.tableView"]
        table.swipeUp()
        table.staticTexts["Report a bug"].tap()
        app.textFields["url"].tap()
        
        let addressTextField = app.textFields["address"]
        addressTextField.tap()
        let url = addressTextField.value as? String
        XCTAssertTrue(url != nil && url!.containsString("https://community.brave.com"))
    }
}
