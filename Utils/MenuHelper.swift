/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

@objc public protocol MenuHelperInterface {
    optional func menuHelperCopy(sender: NSNotification)
    optional func menuHelperOpenAndFill(sender: NSNotification)
    optional func menuHelperReveal(sender: NSNotification)
    optional func menuHelperSecure(sender: NSNotification)
    optional func menuHelperFindInPage(sender: NSNotification)
}

public class MenuHelper: NSObject {
    public static let SelectorCopy: Selector = #selector(MenuHelperInterface.menuHelperCopy(_:))
    public static let SelectorHide: Selector = #selector(MenuHelperInterface.menuHelperSecure(_:))
    public static let SelectorOpenAndFill: Selector = #selector(MenuHelperInterface.menuHelperOpenAndFill(_:))
    public static let SelectorReveal: Selector = #selector(MenuHelperInterface.menuHelperReveal(_:))
    public static let SelectorFindInPage: Selector = #selector(MenuHelperInterface.menuHelperFindInPage(_:))

    public class var defaultHelper: MenuHelper {
        struct Singleton {
            static let instance = MenuHelper()
        }
        return Singleton.instance
    }

    public func setItems() {
        let revealPasswordTitle = Strings.RevealPassword
        let revealPasswordItem = UIMenuItem(title: revealPasswordTitle, action: MenuHelper.SelectorReveal)

        let hidePasswordTitle = Strings.HidePassword
        let hidePasswordItem = UIMenuItem(title: hidePasswordTitle, action: MenuHelper.SelectorHide)

        let copyTitle = Strings.Copy
        let copyItem = UIMenuItem(title: copyTitle, action: MenuHelper.SelectorCopy)

        let openAndFillTitle = Strings.Open_and_Fill
        let openAndFillItem = UIMenuItem(title: openAndFillTitle, action: MenuHelper.SelectorOpenAndFill)

        let findInPageTitle = Strings.Find_in_Page
        let findInPageItem = UIMenuItem(title: findInPageTitle, action: MenuHelper.SelectorFindInPage)

        UIMenuController.sharedMenuController().menuItems = [copyItem, revealPasswordItem, hidePasswordItem, openAndFillItem, findInPageItem]
    }
}
