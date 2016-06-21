/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

protocol WindowTouchFilter: class {
    // return true to block the event
    func filterTouch(touch: UITouch) -> Bool
}

class BraveMainWindow : UIWindow {

    let contextMenuHandler = BraveContextMenu()
    let blankTargetLinkHandler = BlankTargetLinkHandler()

    weak var windowTouchFilter: WindowTouchFilter?

    override func sendEvent(event: UIEvent) {
        contextMenuHandler.sendEvent(event, window: self)
        blankTargetLinkHandler.sendEvent(event, window: self)

        let braveTopVC = getApp().rootViewController.visibleViewController as? BraveTopViewController
        if let _ = braveTopVC, touches = event.touchesForWindow(self), let touch = touches.first where touches.count == 1 {

            if let windowTouchFilter = windowTouchFilter {
                let eaten = windowTouchFilter.filterTouch(touch)
                if eaten {
                    return
                }
            }
        }
        super.sendEvent(event)
    }

}