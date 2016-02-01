/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Crashlytics
import Shared

class BraveSettingsView : AppSettingsTableViewController {

    var debugToggleItemToTriggerCrashCount = 0

    override func generateSettings() -> [SettingSection] {

        let prefs = profile.prefs
        let generalSettings = [
            SearchSetting(settings: self),
//            BoolSetting(prefs: prefs, prefKey: "blockPopups", defaultValue: true,
//                titleText: NSLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting")),
//            BoolSetting(prefs: prefs, prefKey: "saveLogins", defaultValue: true,
//                titleText: NSLocalizedString("Save Logins", comment: "Setting to enable the built-in password manager")),
            BoolSetting(prefs: prefs, prefKey: AdBlocker.prefKeyAdBlockOn, defaultValue: true, titleText: "Block Ads"),
            BoolSetting(prefs: prefs, prefKey: TrackingProtection.prefKeyTrackingProtectionOn, defaultValue: true, titleText: "Tracking Protection"),
            BoolSetting(prefs: prefs, prefKey: HttpsEverywhere.prefKeyHttpsEverywhereOn, defaultValue: true, titleText: "HTTPS Everywhere"),
            BoolSetting(prefs: prefs, prefKey: BraveUX.PrefKeyIsToolbarHidingEnabled , defaultValue: true, titleText: "Hide toolbar when scrolling", statusText: nil, settingDidChange:  { value in
                BraveScrollController.hideShowToolbarEnabled = value

                // Hidden way to trigger a crash for testing
                if (self.debugToggleItemToTriggerCrashCount > 4) {
                    UIAlertView(title: "Trigger a crash for testing", message: "Force a crash?", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "OK").show()
                    self.debugToggleItemToTriggerCrashCount = 0
                } else {
                    self.debugToggleItemToTriggerCrashCount++
                }
            }),
            CookieSetting(settings: self)
        ]

        settings += [
            SettingSection(title: NSAttributedString(string: NSLocalizedString("General", comment: "General settings section title")), children: generalSettings),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Support", comment: "Support section title")), children: [
                ShowIntroductionSetting(settings: self),
                //SendFeedbackSetting(),
                //SendAnonymousUsageDataSetting(prefs: prefs, delegate: settingsDelegate),
                //OpenSupportPageSetting(delegate: settingsDelegate),
                ]),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("About", comment: "About settings section title")), children: [
                VersionSetting(settings: self),
            ])
        ]
        return settings
    }
}

extension BraveSettingsView : UIAlertViewDelegate {
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == alertView.cancelButtonIndex {
            return
        }
        Crashlytics.sharedInstance().crash()
    }
}

// Opens the search settings pane
class CookieSetting: Setting, PicklistSettingDelegate {
    let profile: Profile

    static var prefAcceptCookies = "braveAcceptCookiesPref"

    let heading = "Accept Cookies"
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var style: UITableViewCellStyle { return .Value1 }

    override var status: NSAttributedString {
        let prefs = profile.prefs
        let current = prefs.intForKey(CookieSetting.prefAcceptCookies) ?? 0
        return NSAttributedString(string: CookieSetting.getOption(Int(current)))
    }

    static func getOptions() -> [String] {
        return ["Only from main document domain", "Always", "Never"]
    }

    static func checkIndexOk(index: Int) -> Bool {
        let options = getOptions()
        return 0..<options.count ~= index
    }

    static func getOption(index: Int) -> String {
        let options = getOptions()
        return checkIndexOk(index) ? options[index] : options[0]
    }

    static func indexToPolicy(index: UInt) -> NSHTTPCookieAcceptPolicy {
        switch index {
        case 1:
            return NSHTTPCookieAcceptPolicy.Always
        case 2:
            return NSHTTPCookieAcceptPolicy.Never
        default:
            return NSHTTPCookieAcceptPolicy.OnlyFromMainDocumentDomain
        }
    }

    static func setup() {
        let current = BraveApp.getPref(CookieSetting.prefAcceptCookies) as? Int ?? 0
        NSHTTPCookieStorage.sharedHTTPCookieStorage().cookieAcceptPolicy = CookieSetting.indexToPolicy(UInt(current))
    }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: heading, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = PicklistSetting(options: CookieSetting.getOptions(), title: heading)
        navigationController?.pushViewController(viewController, animated: true)
        viewController.delegate = self
    }

    func picklistSetting(setting: PicklistSetting, pickedIndex: Int) {
//        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
//        for cookie in storage.cookies! {
//            storage.deleteCookie(cookie)
//        }
//        NSUserDefaults.standardUserDefaults().synchronize()

        let prefs = profile.prefs
        prefs.setInt(Int32(pickedIndex), forKey: CookieSetting.prefAcceptCookies)
        NSHTTPCookieStorage.sharedHTTPCookieStorage().cookieAcceptPolicy = CookieSetting.indexToPolicy(UInt(pickedIndex))
    }

}

