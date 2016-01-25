class BraveSettingsView : AppSettingsTableViewController {

    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()

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
            BoolSetting(prefs: prefs, prefKey: BraveUX.PrefKeyIsToolbarHidingEnabled , defaultValue: true, titleText: "Hide toolbar when scrolling", statusText: nil, settingDidChange:  { value in BraveScrollController.hideShowToolbarEnabled = value })

       ]


        var privacySettings = [Setting]()
        privacySettings += [
            BoolSetting(prefs: prefs, prefKey: "crashreports.send.always", defaultValue: false,
                titleText: NSLocalizedString("Send Crash Reports", comment: "Setting to enable the sending of crash reports"),
                settingDidChange: { configureActiveCrashReporter($0) }),
            PrivacyPolicySetting()
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