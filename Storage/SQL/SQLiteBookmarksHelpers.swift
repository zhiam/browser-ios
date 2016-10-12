/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public func titleForSpecialGUID(guid: GUID) -> String? {
    switch guid {
    case BookmarkRoots.RootGUID:
        return "<Root>"
    case BookmarkRoots.MobileFolderGUID:
        return Strings.BookmarksFolderTitleMobile
    case BookmarkRoots.ToolbarFolderGUID:
        return Strings.BookmarksFolderTitleToolbar
    case BookmarkRoots.MenuFolderGUID:
        return Strings.BookmarksFolderTitleMenu
    case BookmarkRoots.UnfiledFolderGUID:
        return Strings.BookmarksFolderTitleUnsorted
    default:
        return nil
    }
}

extension SQLiteBookmarks: ShareToDestination {
    public func addToMobileBookmarks(url: NSURL, title: String, favicon: Favicon?) -> Success {
        return self.insertBookmark(url, title: title, favicon: favicon,
                                   intoFolder: BookmarkRoots.MobileFolderGUID,
                                   withTitle: Strings.BookmarksFolderTitleMobile)
    }

    public func shareItem(item: ShareItem) -> Success {
        // We parse here in anticipation of getting real URLs at some point.
        if let url = item.url.asURL {
            let title = item.title ?? url.absoluteString
            return self.addToMobileBookmarks(url, title: title!, favicon: item.favicon)
        }
        return Success(value: Maybe(failure: DatabaseError(err: nil)))
    }
}
