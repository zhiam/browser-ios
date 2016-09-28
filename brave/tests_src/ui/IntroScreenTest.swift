/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
@testable import Client
import Shared

class IntroScreenTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    private func restart(bootArgs: [String] = []) {
        let app = XCUIApplication()
        
        app.terminate()
        app.launchArguments.append("BRAVE-UI-TEST")
        bootArgs.forEach {
            app.launchArguments.append($0)
        }
        app.launch()
        sleep(1)
    }

    func testIntroScreenAndOptInDialog() {
        restart(["BRAVE-TEST-CLEAR-PREFS"])
        let app = XCUIApplication()
        app.buttons["Start Browsing"].tap()
        app.buttons["Yes"].tap()
    }

    func testOptInDialogWithoutIntroScreen() {
        restart(["BRAVE-TEST-NO-SHOW-INTRO", "BRAVE-TEST-SHOW-OPT-IN"])
        let app = XCUIApplication()
        app.buttons["Yes"].tap()

        restart()
        // Ensure UI isn't blocked with modal dialog
        sleep(1)
        app.buttons["Bookmarks and History Panel"].tap()
        app.scrollViews.otherElements.buttons["Settings"].tap()
    }
}
