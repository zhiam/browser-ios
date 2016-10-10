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

func restart(bootArgs: [String] = []) {
    let app = XCUIApplication()

    app.terminate()
    app.launchArguments.append("BRAVE-UI-TEST")
    bootArgs.forEach {
        app.launchArguments.append($0)
    }
    app.launch()
    sleep(1)
}

class IntroScreenTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testIntroScreenAndOptInDialog() {
        restart(["BRAVE-TEST-CLEAR-PREFS"])
        let app = XCUIApplication()
        app.buttons["Start Browsing"].tap()
        app.buttons["Accept & Continue"].tap()
    }

    func testOptInDialogWithoutIntroScreen() {
        restart(["BRAVE-TEST-NO-SHOW-INTRO", "BRAVE-TEST-SHOW-OPT-IN"])
        let app = XCUIApplication()
        app.buttons["Accept & Continue"].tap()

        restart()
        // Ensure UI isn't blocked with modal dialog
        sleep(1)
        app.buttons["Bookmarks and History Panel"].tap()
        app.scrollViews.otherElements.buttons["Settings"].tap()
    }
}
