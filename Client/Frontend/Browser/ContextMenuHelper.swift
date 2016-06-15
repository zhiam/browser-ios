/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared

protocol ContextMenuHelperDelegate: class {
    func contextMenuHelper(contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UILongPressGestureRecognizer)
}

class ContextMenuHelper: NSObject, BrowserHelper, UIGestureRecognizerDelegate {
    private weak var browser: Browser?
    weak var delegate: ContextMenuHelperDelegate?
    private let gestureRecognizer = UILongPressGestureRecognizer()

    struct Elements {
        let link: NSURL?
        let image: NSURL?
    }

    /// Clicking an element with VoiceOver fires touchstart, but not touchend, causing the context
    /// menu to appear when it shouldn't (filed as rdar://22256909). As a workaround, disable the custom
    /// context menu for VoiceOver users.
    private var showCustomContextMenu: Bool {
        return !UIAccessibilityIsVoiceOverRunning()
    }

    required init(browser: Browser) {
        super.init()

        self.browser = browser
    }

    class func scriptMessageHandlerName() -> String? {
        return "contextMenuMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if !showCustomContextMenu {
            return
        }

        guard let data = message.body as? [String: AnyObject] else { return }

        // On sites where <a> elements have child text elements, the text selection delegate can be triggered
        // when we show a context menu. To prevent this, cancel the text selection delegate if we know the
        // user is long-pressing a link.
        if let handled = data["handled"] as? Bool where handled {
          func blockOtherGestures(views: [UIView]) {
            for view in views {
              if let gestures = view.gestureRecognizers as [UIGestureRecognizer]! {
                for gesture in gestures {
                  if gesture is UILongPressGestureRecognizer && gesture != gestureRecognizer {
                    // toggling gets the gesture to ignore this long press
                    gesture.enabled = false
                    gesture.enabled = true
                  }
                }
              }
            }
          }

          blockOtherGestures((browser?.webView?.scrollView.subviews)!)
        }

        var linkURL: NSURL?
        if let urlString = data["link"] as? String {
            linkURL = NSURL(string: urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLAllowedCharacterSet())!)
        }

        var imageURL: NSURL?
        if let urlString = data["image"] as? String {
            imageURL = NSURL(string: urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLAllowedCharacterSet())!)
        }

        if linkURL != nil || imageURL != nil {
            let elements = Elements(link: linkURL, image: imageURL)
            delegate?.contextMenuHelper(self, didLongPressElements: elements, gestureRecognizer: gestureRecognizer)
        }
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return showCustomContextMenu
    }
}