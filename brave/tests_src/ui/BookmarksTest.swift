/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class BookmarksTest: XCTestCase {

    func testAddDeleteBookmark() {
        restart(["BRAVE-DELETE-BOOKMARKS"])
        let app = XCUIApplication()

        app.textFields["url"].tap()
        let topSitesViewCollectionView = app.collectionViews["Top Sites View"]
        topSitesViewCollectionView.cells["google"].tap()
        let bookmarksAndHistoryPanelButton = app.buttons["Bookmarks and History Panel"]
        bookmarksAndHistoryPanelButton.tap()
        
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.buttons["Show Bookmarks"].tap()

        var bmCount = app.tables.element.cells.count
        elementsQuery.buttons["Add Bookmark"].tap()
        XCTAssert(app.tables.element.cells.count > bmCount)
        // close panel
        //app.otherElements["webViewContainer"].tap()
        app.coordinateWithNormalizedOffset(CGVector(dx: UIScreen.mainScreen().bounds.width, dy:  UIScreen.mainScreen().bounds.height)).tap()

        // switch to yahoo
        app.textFields["url"].tap()
        topSitesViewCollectionView.cells["yahoo"].tap()
        bookmarksAndHistoryPanelButton.tap()

        // load google from bookmarks
        let googleStaticText = app.scrollViews.otherElements.tables["SiteTable"].staticTexts["Google"]
        googleStaticText.tap()
        XCTAssert(app.links["IMAGES"].exists, "google web page main image showing")
        XCTAssert(app.links["Use precise location"].exists, "google web page main image showing")

        // delete the bookmark
        bookmarksAndHistoryPanelButton.tap()
        let toolbarsQuery = elementsQuery.toolbars
        toolbarsQuery.buttons["Edit"].tap()
        bmCount = app.tables.element.cells.count
        app.scrollViews.otherElements.tables["SiteTable"].buttons["Delete Google"].tap()
        app.scrollViews.otherElements.tables["SiteTable"].buttons["Delete"].tap()
        toolbarsQuery.buttons["Done"].tap()
        elementsQuery.navigationBars["Bookmarks"].staticTexts["Bookmarks"].tap()
        elementsQuery.tables["SiteTable"].tap()

        // close the panel
        app.coordinateWithNormalizedOffset(CGVector(dx: UIScreen.mainScreen().bounds.width, dy:  UIScreen.mainScreen().bounds.height)).tap()
    }
}
