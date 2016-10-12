/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class WebViewTest: XCTestCase {

    func testLongPress() {
        let app = XCUIApplication()
        app.launch()
        app.textFields["url"].tap()
        let topSitesViewCollectionView = app.collectionViews["Top Sites View"]
        topSitesViewCollectionView.cells["google"].tap()

        app.staticTexts["IMAGES"].pressForDuration(1.5);
        app.sheets.elementBoundByIndex(0).buttons["Open In Background"].tap()
        app.buttons["2"].tap()
        app.collectionViews.childrenMatchingType(.Cell).matchingIdentifier("Google").elementBoundByIndex(1).tap()
    }
    
}
