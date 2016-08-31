/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

protocol WindowTouchFilter: class {
    // return true to block the event
    func filterTouch(touch: UITouch) -> Bool
}

class BraveMainWindow : UIWindow {

    let contextMenuHandler = BraveContextMenu()
    let blankTargetLinkHandler = BlankTargetLinkHandler()

    class Weak_WindowTouchFilter {     // We can't use a WeakList here because this is a protocol.
        weak var value : WindowTouchFilter?
        init (value: WindowTouchFilter) { self.value = value }
    }
    private var delegatesForTouchFiltering = [Weak_WindowTouchFilter]()

    // Guarantee: *All* filters will see the event.
    // *Any* filter can stop the call to super.sendEvent
    func addTouchFilter(filter: WindowTouchFilter) {
        delegatesForTouchFiltering = delegatesForTouchFiltering.filter { $0.value != nil }
        delegatesForTouchFiltering.append(Weak_WindowTouchFilter(value: filter))
    }

    override func sendEvent(event: UIEvent) {
        if let touchView = event.allTouches()?.first?.view where "\(touchView.dynamicType)" == "UIWebBrowserView" {
            contextMenuHandler.sendEvent(event, window: self)
            blankTargetLinkHandler.sendEvent(event, window: self)

        }

        let braveTopVC = getApp().rootViewController.visibleViewController as? BraveTopViewController
        if let _ = braveTopVC, touches = event.touchesForWindow(self), let touch = touches.first where touches.count == 1 {
            var eaten = false
            for filter in delegatesForTouchFiltering where filter.value != nil {
                if filter.value!.filterTouch(touch) {
                    eaten = true
                }
            }
            if eaten {
                return
            }
        }
        super.sendEvent(event)
    }
}