/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Using suggestions from: http://www.icab.de/blog/2010/07/11/customize-the-contextual-menu-of-uiwebview/

let kNotificationMainWindowTapAndHold = "kNotificationMainWindowTapAndHold"

class BraveContextMenu {
    var tapLocation: CGPoint = CGPointZero
    var contextualMenuTimer: NSTimer = NSTimer()
    var tappedElement: ContextMenuHelper.Elements?

    private func resetTimer() {
        contextualMenuTimer.invalidate()
        tappedElement = nil
    }

    private func isBrowserTopmostAndNoPanelsOpen() ->  Bool {
        guard let top = getApp().rootViewController.visibleViewController as? BraveTopViewController else {
            return false
        }

        return top.mainSidePanel.view.hidden && top.rightSidePanel.view.hidden
    }

    func sendEvent(event: UIEvent, window: UIWindow) {
        if !isBrowserTopmostAndNoPanelsOpen() {
            resetTimer()
            return
        }

        if let touches = event.touchesForWindow(window), let touch = touches.first where touches.count == 1 {
            guard let webView = BraveApp.getCurrentWebView(), webViewSuperview = webView.superview  else { return }
            let globalRect = webViewSuperview.convertRect(webView.frame, toView: nil)
            if !globalRect.contains(touch.locationInView(window)) {
                resetTimer()
                return
            }
            webView.lastTappedTime = NSDate()
            switch touch.phase {
            case .Began:  // A finger touched the screen
                tapLocation = touch.locationInView(window)
                resetTimer()
                // This timer repeats in order to run twice. See tapAndHoldAction() for comments.
                contextualMenuTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: #selector(BraveContextMenu.tapAndHoldAction), userInfo: nil, repeats: true)
                break
            case .Moved, .Stationary:
                let p1 = touch.locationInView(window)
                let p2 = touch.previousLocationInView(window)
                let distance =  hypotf(Float(p1.x) - Float(p2.x), Float(p1.y) - Float(p2.y))
                if distance > 1.0 {
                    resetTimer()
                }
                break
            case .Ended, .Cancelled:
                resetTimer()
                break
            }
        } else {
            resetTimer()
        }
    }

    // This is called 2x, once at .25 seconds to ensure the native context menu is cancelled,
    // then again at .5 seconds to show our context menu. (This code was borne of frustration, not ideal flow)
    @objc func tapAndHoldAction() {
        if !isBrowserTopmostAndNoPanelsOpen() {
            resetTimer()
            return
        }

        func showContextMenuForElement(tappedElement:  ContextMenuHelper.Elements) {
            let info = ["point": NSValue(CGPoint: tapLocation)]
            NSNotificationCenter.defaultCenter().postNotificationName(kNotificationMainWindowTapAndHold, object: self, userInfo: info)
            guard let bvc = getApp().browserViewController else { return }
            if bvc.urlBar.inOverlayMode {
                return
            }
            bvc.showContextMenu(elements: tappedElement, touchPoint: tapLocation)
            resetTimer()
            return
        }

        func extractElementAndBlockNativeMenu() {
            guard let hit = ElementAtPoint().getHit(tapLocation) else {
                resetTimer()
                return
            }

            tappedElement = ContextMenuHelper.Elements(link: hit.url != nil ? NSURL(string: hit.url!) : nil, image: hit.image != nil ? NSURL(string: hit.image!) : nil)

            func blockOtherGestures(views: [UIView]?) {
                guard let views = views else { return }
                for view in views {
                    if let gestures = view.gestureRecognizers as [UIGestureRecognizer]! {
                        for gesture in gestures {
                            if gesture is UILongPressGestureRecognizer {
                                // toggling gets the gesture to ignore this long press
                                gesture.enabled = false
                                gesture.enabled = true
                            }
                        }
                    }
                }
            }

            blockOtherGestures(BraveApp.getCurrentWebView()?.scrollView.subviews)
        }

        if let tappedElement = tappedElement {
            showContextMenuForElement(tappedElement)
        } else {
            extractElementAndBlockNativeMenu()
        }
    }
}