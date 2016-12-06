/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class FingerprintingProtection: NSObject, BrowserHelper {
    private weak var browser: Browser?

    static var script: String = {
        let path = NSBundle.mainBundle().pathForResource("FingerprintingProtection", ofType: "js")!
        return try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
    }()

    required init(browser: Browser) {
        super.init()

        self.browser = browser

        let userScript = WKUserScript(source: FingerprintingProtection.script, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: true)
        browser.webView?.configuration.userContentController.addUserScript(userScript)
    }

    class func scriptMessageHandlerName() -> String? {
        return "fingerprinting"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        //browser?.webView?.shieldStatUpdate(.fpIncrement)
        print("fingerprint \(message.body)")
    }
}
