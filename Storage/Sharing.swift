/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

// A small structure to encapsulate all the possible data that we can get
// from an application sharing a web page or a URL.
public struct ShareItem {
    public let url: String
    public let title: String?
    public let favicon: Favicon?
    public let folderId: String?
    public let folderTitle: String?
    public let completion: dispatch_block_t?

    public init(url: String, title: String?, favicon: Favicon?, folderId:String? = nil, folderTitle:String? = nil, completion: dispatch_block_t? = nil) {
        self.url = url
        self.title = title
        self.favicon = favicon
        self.folderId = folderId
        self.folderTitle = folderTitle
        self.completion = completion
    }
}

public protocol ShareToDestination {
    func shareItem(item: ShareItem) -> Success
}
