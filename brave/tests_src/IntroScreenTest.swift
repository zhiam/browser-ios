/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
@testable import Client
import Shared

class IntroScreenTest: XCTestCase {

    override func setUp() {
        super.setUp()
        restart(reset: true)
    }

    override func tearDown() {
        super.tearDown()
    }

    func restart(reset reset: Bool) {
        let app = XCUIApplication()
        
        app.terminate()
       /* app.launchArguments.append("BRAVE-UI-TEST")
        if reset {
            app.launchArguments.append("BRAVE-TEST-RESET")
        }*/
        app.launch()
        sleep(1)
    }


    func testIntroScreen() {
       // getApp().profile?.prefs.removeObjectForKey(IntroViewControllerSeenProfileKey)

        
    }
}
