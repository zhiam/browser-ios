/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared

private let log = Logger.syncLogger

public class SQLiteBookmarks: BookmarksModelFactorySource {
    let db: BrowserDB
    let favicons: FaviconsTable<Favicon>

    public lazy var modelFactory: Deferred<Maybe<BookmarksModelFactory>> =
        deferMaybe(SQLiteBookmarksModelFactory(bookmarks: self, direction: .Local))

    public init(db: BrowserDB) {
        self.db = db
        self.favicons = FaviconsTable<Favicon>()
    }
}
