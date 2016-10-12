/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class BookmarksTest: XCTestCase {

    private func addGoogleAsFirstBookmark() {
        let app = XCUIApplication()
        app.textFields["url"].tap()
        let topSitesViewCollectionView = app.collectionViews["Top Sites View"]
        topSitesViewCollectionView.cells["google"].tap()
        let bookmarksAndHistoryPanelButton = app.buttons["Bookmarks and History Panel"]
        bookmarksAndHistoryPanelButton.tap()

        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.buttons["Show Bookmarks"].tap()

        let bmCount = app.tables.element.cells.count
        elementsQuery.buttons["Add Bookmark"].tap()
        XCTAssert(app.tables.element.cells.count > bmCount)
    }

    func testAddDeleteBookmark() {
        restart(["BRAVE-DELETE-BOOKMARKS"])
        let app = XCUIApplication()

        addGoogleAsFirstBookmark()

        let topSitesViewCollectionView = app.collectionViews["Top Sites View"]
        let bookmarksAndHistoryPanelButton = app.buttons["Bookmarks and History Panel"]
        let elementsQuery = app.scrollViews.otherElements

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

        // TODO: find a better way to see if google is loaded, other than looking for links on the page
        [app.links["IMAGES"], app.links["Advertising"]].forEach {
            let predicate = NSPredicate(format: "exists == 1")
            expectationForPredicate(predicate, evaluatedWithObject: $0, handler: nil)
            waitForExpectationsWithTimeout(3, handler: nil)
        }

        // delete the bookmark
        bookmarksAndHistoryPanelButton.tap()
        let toolbarsQuery = elementsQuery.toolbars
        toolbarsQuery.buttons["Edit"].tap()
        let bmCount = app.tables.element.cells.count
        app.scrollViews.otherElements.tables["SiteTable"].buttons["Delete Google"].tap()
        app.scrollViews.otherElements.tables["SiteTable"].buttons["Delete"].tap()
        XCTAssert(app.tables.element.cells.count < bmCount)
        toolbarsQuery.buttons["Done"].tap()
        elementsQuery.navigationBars["Bookmarks"].staticTexts["Bookmarks"].tap()
        elementsQuery.tables["SiteTable"].tap()

        // close the panel
        app.coordinateWithNormalizedOffset(CGVector(dx: UIScreen.mainScreen().bounds.width, dy:  UIScreen.mainScreen().bounds.height)).tap()
    }


    func testFolderNav() {
        restart(["BRAVE-DELETE-BOOKMARKS"])
        let app = XCUIApplication()

        addGoogleAsFirstBookmark()

        let toolbarsQuery = app.scrollViews.otherElements.toolbars
        toolbarsQuery.buttons["Edit"].tap()
        toolbarsQuery.buttons["New Folder"].tap()

        let collectionViewsQuery = app.alerts["New Folder"].collectionViews
        collectionViewsQuery.textFields["<folder name>"].typeText("Foo")
        app.buttons["OK"].tap()
        app.scrollViews.otherElements.tables["SiteTable"].staticTexts["Google"].tap()


        app.scrollViews.otherElements.tables.staticTexts["Root Folder"].tap()
        app.pickerWheels.elementBoundByIndex(0).adjustToPickerWheelValue("Foo")
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.navigationBars["Bookmarks"].buttons["Bookmarks"].tap()

        XCTAssert(app.scrollViews.otherElements.tables["SiteTable"].cells.count == 1)

        toolbarsQuery.buttons["Done"].tap()

        app.scrollViews.otherElements.tables["SiteTable"].staticTexts["Foo"].tap()
        toolbarsQuery.buttons["Edit"].tap()
        app.scrollViews.otherElements.tables["SiteTable"].staticTexts["Google"].tap()

        // close the panel (bug #448)
        app.coordinateWithNormalizedOffset(CGVector(dx: UIScreen.mainScreen().bounds.width, dy:  UIScreen.mainScreen().bounds.height)).tap()
    }
}
