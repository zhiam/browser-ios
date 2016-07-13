/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

/**
 * Handles screenshots for a given browser, including pages with non-webview content.
 */
class ScreenshotHelper {
    var viewIsVisible = false

    private weak var controller: BrowserViewController?

    init(controller: BrowserViewController) {
        self.controller = controller
    }

    func takeScreenshot(tab: Browser) {
        var screenshot: UIImage?

        if let url = tab.url {
            if AboutUtils.isAboutHomeURL(url) {
                if let homePanel = controller?.homePanelController {
                    screenshot = homePanel.view.screenshot()
                }
            } else if let wv = tab.webView {
                let offset = CGPointMake(0, -wv.scrollView.contentInset.top)
                // If webview is hidden, need to add it for screenshot. On slow devices, don't do this
                let showForScreenshot = wv.superview == nil && DeviceInfo.isBlurSupported()
                if showForScreenshot {
                    getApp().rootViewController.view.insertSubview(wv, atIndex: 0)
                }
                delay(0.1) { [weak tab] in
                    screenshot = tab?.webView?.screenshot(offset: offset)
                    tab?.setScreenshot(screenshot)
                    if showForScreenshot {
                        tab?.webView?.removeFromSuperview()
                    }
                }
                return
            }
        }

        tab.setScreenshot(screenshot)
    }

    /// Takes a screenshot after a small delay.
    /// Trying to take a screenshot immediately after didFinishNavigation results in a screenshot
    /// of the previous page, presumably due to an iOS bug. Adding a brief delay fixes this.
    func takeDelayedScreenshot(tab: Browser) {
        delay(1) { [weak self, weak tab = tab] in
            // If the view controller isn't visible, the screenshot will be blank.
            // Wait until the view controller is visible again to take the screenshot.
            guard self?.viewIsVisible ?? false else {
                tab?.pendingScreenshot = true
                return
            }

            if let tab = tab {
                self?.takeScreenshot(tab)
            }
        }
    }

    func takePendingScreenshots(tabs: [Browser]) {
        for tab in tabs where tab.pendingScreenshot {
            tab.pendingScreenshot = false
            takeDelayedScreenshot(tab)
        }
    }
}
