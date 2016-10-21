/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

extension XCUIElement {
    func forceTapElement() {
        if self.hittable {
            self.tap()
        }
        else {
            let coordinate: XCUICoordinate = self.coordinateWithNormalizedOffset(CGVectorMake(0.0, 0.0))
            coordinate.tap()
        }
    }
}

class UITestUtils {
    static func loadSite(_ app:XCUIApplication, _ site: String) {
        app.textFields["url"].tap()
        app.textFields["address"].typeText(site)
        app.typeText("\r")
    }

    static func pasteTextFieldText(app:XCUIApplication, element:XCUIElement, value:String) {
        UIPasteboard.generalPasteboard().string = value
        element.tap()
        app.menuItems["Paste"].tap()
    }

    static func restart(bootArgs: [String] = []) {
        let app = XCUIApplication()

        app.terminate()
        app.launchArguments.append("BRAVE-UI-TEST")
        bootArgs.forEach {
            app.launchArguments.append($0)
        }
        app.launch()
    }

    static func waitForGooglePageLoad(test: XCTestCase) {
        let app = XCUIApplication()
        // TODO: find a better way to see if google is loaded, other than looking for links on the page
        [app.links["IMAGES"], app.links["Advertising"]].forEach {
            let predicate = NSPredicate(format: "exists == 1")
            test.expectationForPredicate(predicate, evaluatedWithObject: $0, handler: nil)
            test.waitForExpectationsWithTimeout(3, handler: nil)
        }
    }
}
