/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class DashlaneActivity: UIActivity {
    override func activityTitle() -> String? {
        return NSLocalizedString("Dashlane", tableName: "Dashlane", comment: "Share action title")
    }

    override func activityImage() -> UIImage? {
        return UIImage(named: "dashlane")
    }

    override func performActivity() {
        if let url = BraveApp.getCurrentWebView()?.URL {
            let extHelper = DashlaneExtensionRequestHelper(appName: DeviceInfo.appName())
            extHelper.requestLoginAndPasswordForAService(url.absoluteString) {
                results, error in
                if results != nil {
                    if let requestInfo: [String:String] = results[DASHLANE_EXTENSION_REQUEST_LOGIN] as? [String: String] {
                        let login = requestInfo[DASHLANE_EXTENSION_REQUEST_REPLY_LOGIN_KEY]
                        let pw = requestInfo[DASHLANE_EXTENSION_REQUEST_REPLY_PASSWORD_KEY]

                        let javascript = "!! function(e,t) {var l=document.querySelectorAll('input[type=\"text\"],input[type=\"email\"]'), u=document.querySelectorAll('input[type=\"password\"]');return u && u.length && l && l.length ?(l[0].value=e,u[0].value=t,!0):!1}(\"\(login ?? "")\",\"\(pw ?? "")\");"
                        BraveApp.getCurrentWebView()?.stringByEvaluatingJavaScriptFromString(javascript)
                    }
                }
            }
        }

        activityDidFinish(true)
    }

    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return true
    }
}
