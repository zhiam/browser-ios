/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/*
 BraveWebView will, on new load, assume that blank link tap detection is required.
 On load finished, it runs a check to see if any links are _blank targets, and if not, disables this tap detection.
 */

class BlankTargetLinkHandler {
//    private static var enabled = false
//    static func updatedEnabledState() {
//        if let profile = getApp().profile {
//            enabled = !(profile.prefs.boolForKey("blockPopups") ?? true)
//        }
//    }

    func isBrowserTopmost() -> Bool {
        return getApp().rootViewController.visibleViewController as? BraveTopViewController != nil
    }

    func sendEvent(event: UIEvent, window: UIWindow) {
//        if !LinkTargetBlankHandler.enabled {
//            return
//        }

        if !isBrowserTopmost() {
            return
        }

        if let touches = event.touchesForWindow(window), let touch = touches.first where touches.count == 1 {
            guard let webView = BraveApp.getCurrentWebView(), webViewSuperview = webView.superview  else { return }
            if !webView.blankTargetLinkDetectionOn {
                return
            }

            let globalRect = webViewSuperview.convertRect(webView.frame, toView: nil)
            if !globalRect.contains(touch.locationInView(window)) {
                return
            }

            switch touch.phase {
            case .Began:  // A finger touched the screen
                let tapLocation = touch.locationInView(window)
                if let element = ElementAtPoint().getHit(tapLocation),
                    url = element.url,
                    t = element.urlTarget where t == "_blank"
                {
                    webView.urlBlankTargetTapped(url)
                    print("LinkTargetBlankHandler \(element)")
                }

                break
            case .Moved, .Stationary:
                break
            case .Ended, .Cancelled:
                break
            }
        }
    }
}