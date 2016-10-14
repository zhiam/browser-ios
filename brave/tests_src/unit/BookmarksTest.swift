/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
@testable import Client
import Shared
import Storage

class BookmarksTest: XCTestCase {
    func testNewFolder() {
        let expect = expectationWithDescription("folder-added")

        if let sqllitbk = getApp().profile!.bookmarks as? MergedSQLiteBookmarks {
            sqllitbk.createFolder("FOOFOO").upon { _ in
                postAsyncToMain {
                    expect.fulfill()
                }
            }
        }

        waitForExpectationsWithTimeout(20) { (error:NSError?) -> Void in
            if let _ = error {
                XCTAssert(false, "failed")
            }
        }
    }
}
