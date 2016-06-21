/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import SnapKit

struct ShieldBlockedStats {
    var abAndTp = 0
    var httpse = 0
    var js = 0
    var fp = 0
}

class BraveRightSidePanelViewController : SidePanelBaseViewController {

    let heading = UILabel()
    let siteName = UILabel()
    let shieldToggle = UISwitch()
    let shieldToggleTitle = UILabel()
    let toggleHttpse =  UISwitch()
    let toggleHttpseTitle =  UILabel()
    let toggleBlockAds = UISwitch()
    let toggleBlockAdsTitle =  UILabel()
    let toggleBlockScripts = UISwitch()
    let toggleBlockScriptsTitle =  UILabel()
    let toggleBlockMalware = UISwitch()
    let toggleBlockMalwareTitle =  UILabel()
    let toggleBlockFingerprinting = UISwitch()
    let toggleBlockFingerprintingTitle =  UILabel()

    let togglesContainer = UIView()
    let headerContainer = UIView()
    let siteNameContainer = UIView()
    let statsContainer = UIView()

    let statAdsBlocked = UILabel()
    let statHttpsUpgrades = UILabel()
    let statFPBlocked = UILabel()
    let statScriptsBlocked = UILabel()

    let ui_edgeInset = 15

    override var canShow: Bool {
        let site = BraveApp.getCurrentWebView()?.URL?.normalizedHost()
        return site != nil && getApp().browserViewController.homePanelController == nil
    }

    override func viewDidLoad() {
        isLeftSidePanel = false
        super.viewDidLoad()
    }

    override func setupContainerViewSize() {
        var h = max(UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.width)
        h = min(700, h)
        containerView.frame = CGRectMake(0, 0, CGFloat(BraveUX.WidthOfSlideOut), h)
        viewAsScrollView().contentSize = CGSizeMake(containerView.frame.width, containerView.frame.height)
    }

    private func isTinyScreen() -> Bool{
        let h = max(UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.width)
        return h < 500
    }

    override func setupUIElements() {
        super.setupUIElements()

        let sections = [headerContainer, siteNameContainer, statsContainer, togglesContainer]
        sections.forEach { containerView.addSubview($0) }
        sections.enumerate().forEach { i, section in
            section.snp_makeConstraints(closure: { (make) in
                make.left.right.equalTo(section.superview!)

                if i == 0 {
                    make.top.equalTo(section.superview!)
                    make.height.equalTo(44 + spaceForStatusBar())
                } else if i == sections.count - 1 {
                    make.bottom.equalTo(section.superview!)
                } else {
                    make.top.equalTo(sections[i - 1].snp_bottom)
                    make.bottom.equalTo(sections[i + 1].snp_top)
                }

                if section === siteNameContainer {
                    make.height.equalTo(80)
                } else if section === statsContainer {
                    make.height.equalTo(isTinyScreen() ? 140 : 180)
                }
            })
        }

        headerContainer.backgroundColor = UIColor(white: 93/255.0, alpha: 1.0)
        siteNameContainer.backgroundColor = UIColor(white: 230/255.0, alpha: 1.0)
        statsContainer.backgroundColor = UIColor(white: 244/255.0, alpha: 1.0)
        togglesContainer.backgroundColor = UIColor.init(white: 252.0/255.0, alpha: 1.0)

        viewAsScrollView().scrollEnabled = true
        viewAsScrollView().bounces = false

        view.backgroundColor = togglesContainer.backgroundColor
        containerView.backgroundColor = togglesContainer.backgroundColor

        func setupHeaderSection() {
            headerContainer.addSubview(heading)

            heading.text = "Brave shield site settings"
            heading.textColor = UIColor.whiteColor()
            heading.font = UIFont.boldSystemFontOfSize(18)

            heading.snp_makeConstraints { (make) in
                make.right.equalTo(heading.superview!)
                make.bottom.equalTo(heading.superview!).inset(12)
                make.left.equalTo(heading.superview!).offset(ui_edgeInset)
            }
        }
        setupHeaderSection()

        func setupSiteNameSection() {
            siteName.font = UIFont.boldSystemFontOfSize(22)

            let down = UILabel()
            down.text = "Down"
            let up = UILabel()
            up.text = "Up"

            [siteName, up, down, shieldToggle].forEach { siteNameContainer.addSubview($0) }

            siteName.snp_makeConstraints {
                make in
                make.left.equalTo(siteName.superview!).inset(ui_edgeInset)
                make.right.equalTo(siteName.superview!).inset(ui_edgeInset)
                make.bottom.equalTo(shieldToggle.snp_top).inset(-8)
            }

            siteName.adjustsFontSizeToFitWidth = true

            [down, up].forEach {
                $0.font = UIFont.boldSystemFontOfSize(14)
            }

            down.snp_makeConstraints {
                make in
                make.left.equalTo(down.superview!).inset(ui_edgeInset + 2)
                make.centerY.equalTo(shieldToggle)
            }

            up.snp_makeConstraints {
                make in
                make.left.equalTo(shieldToggle.snp_right).offset(10)
                make.centerY.equalTo(shieldToggle)
            }

            shieldToggle.snp_makeConstraints {
                make in
                make.left.equalTo(down.snp_right).offset(8)
                make.top.equalTo(shieldToggle.superview!.snp_centerY)
            }
            shieldToggle.onTintColor = BraveUX.BraveOrange
            shieldToggle.addTarget(self, action: #selector(switchToggled(_:)), forControlEvents: .ValueChanged)
        }
        setupSiteNameSection()

        func setupSwitchesSection() {
            let views_toggles = [toggleBlockAds, toggleHttpse, toggleBlockMalware, toggleBlockScripts, toggleBlockFingerprinting]
            let views_labels = [toggleBlockAdsTitle, toggleHttpseTitle, toggleBlockMalwareTitle, toggleBlockScriptsTitle, toggleBlockFingerprintingTitle]
            let labelTitles = ["Block Ads & Tracking", "HTTPS Everywhere", "Block Phishing", "Block Scripts", "Fingerprinting\nProtection"]

            func layoutSwitch(switchItem: UISwitch, label: UILabel) -> UIView {
                let row = UIView()
                togglesContainer.addSubview(row)
                row.addSubview(switchItem)
                row.addSubview(label)
                
                switchItem.snp_makeConstraints { (make) in
                    make.left.equalTo(row)
                    make.centerY.equalTo(row)
                }

                label.snp_makeConstraints { make in
                    make.left.equalTo(switchItem.snp_right).offset(10)
                    make.centerY.equalTo(switchItem.snp_centerY)
                }

                return row
            }

            var rows = [UIView]()
            for (i, item) in views_toggles.enumerate() {
                item.onTintColor = BraveUX.BraveOrange.colorWithAlphaComponent(0.8)
                item.addTarget(self, action: #selector(switchToggled(_:)), forControlEvents: .ValueChanged)
                views_labels[i].text = labelTitles[i]
                if UIDevice.currentDevice().userInterfaceIdiom != .Pad {
                    views_labels[i].font = UIFont.systemFontOfSize(UIFont.systemFontSize() - 1)
                }
                rows.append(layoutSwitch(item, label: views_labels[i]))
            }

            let topAndBottomSpace = isTinyScreen() ? 4 : ui_edgeInset
            rows.enumerate().forEach { i, row in
                row.snp_makeConstraints(closure: { (make) in
                    make.left.right.equalTo(row.superview!).inset(ui_edgeInset)
                    if i == 0 {
                        make.top.equalTo(row.superview!).offset(topAndBottomSpace)
                        make.bottom.equalTo(rows[i + 1].snp_top)
                    } else if i == rows.count - 1 {
                        make.top.greaterThanOrEqualTo(rows[i - 1].snp_bottom)
                        make.bottom.equalTo(row.superview!).inset(topAndBottomSpace)
                    } else {
                        make.top.greaterThanOrEqualTo(rows[i - 1].snp_bottom)
                        make.bottom.equalTo(rows[i + 1].snp_top)
                    }
                    if i > 0 {
                        make.height.equalTo(rows[0])
                    }
                })
            }

            toggleBlockFingerprintingTitle.lineBreakMode = .ByWordWrapping
            toggleBlockFingerprintingTitle.numberOfLines = 2
        }

        setupSwitchesSection()

        func setupStatsSection() {
            let line = UIView()
            line.backgroundColor = view.backgroundColor
            containerView.addSubview(line)
            line.snp_makeConstraints { (make) in
                make.left.right.equalTo(line.superview!)
                make.centerY.equalTo(statsContainer.snp_top)
                make.height.equalTo(4)
            }

            let statTitles = ["Ads & Trackers Blocked", "HTTPS Upgrades", "Scripts Blocked",  "Fingerprinting Methods\nBlocked"]
            let statViews = [statAdsBlocked, statHttpsUpgrades, statScriptsBlocked, statFPBlocked]
            let statColors = [UIColor(red:234/255.0, green:90/255.0, blue:45/255.0, alpha:1),
                              UIColor(red:242/255.0, green:142/255.0, blue:45/255.0, alpha:1),
                              UIColor(red:26/255.0, green:152/255.0, blue:252/255.0, alpha:1),
                              UIColor.init(white: 140/255.0, alpha: 1)]
            var prevTitle:UIView? = nil
            for (i, stat) in statViews.enumerate() {
                let label = UILabel()
                label.text = statTitles[i]
                statsContainer.addSubview(label)
                statsContainer.addSubview(stat)

                stat.text = "0"
                stat.font = UIFont.boldSystemFontOfSize(28)
                stat.adjustsFontSizeToFitWidth = true
                stat.textColor = statColors[i]

                stat.snp_makeConstraints {
                    make in
                    make.left.equalTo(stat.superview!).offset(ui_edgeInset)
                    if let prevTitle = prevTitle {
                        if i == statViews.count - 1 {
                            make.bottom.equalTo(stat.superview!)
                        }
                        make.top.equalTo(prevTitle.snp_bottom)

                    } else {
                        make.top.equalTo(stat.superview!)
                    }
                    make.width.equalTo(40)
                    make.height.equalTo(statViews[0])
                }

                label.snp_makeConstraints(closure: { (make) in
                    make.left.equalTo(stat.snp_right).offset(6)
                    make.centerY.equalTo(stat)
                })

                prevTitle = label

                if UIDevice.currentDevice().userInterfaceIdiom != .Pad {
                    label.font = UIFont.systemFontOfSize(UIFont.systemFontSize() - 1)
                }

                if label.text?.contains("Fingerprint") ?? false {
                    label.lineBreakMode = .ByWordWrapping
                    label.numberOfLines = 2
                }
            }
        }
        setupStatsSection()
    }

    @objc func switchToggled(sender: UISwitch) {
        guard let site = siteName.text else { return }

        func setKeys(globalPrefKey: String, _ globalPrefDefaultValue: Bool, _ siteShieldKey: String) {
            var state: Bool? = nil
            if siteShieldKey == BraveShieldState.kAllOff {
                state = !sender.on
            } else {
                // state matches the prefs setting
                let pref = BraveApp.getPrefs()?.boolForKey(globalPrefKey) ?? globalPrefDefaultValue
                if sender.on != pref {
                    state = sender.on
                }
            }
            getApp().profile?.setBraveShieldForNormalizedDomain(site, state: (siteShieldKey, state))
            (getApp().browserViewController as! BraveBrowserViewController).updateBraveShieldButtonState(animated: true)
            BraveApp.getCurrentWebView()?.reload()
        }

        switch (sender) {
        case toggleBlockAds:
            setKeys(AdBlocker.prefKey, AdBlocker.prefKeyDefaultValue,  BraveShieldState.kAdBlockAndTp)
        case toggleBlockMalware:
            setKeys(SafeBrowsing.prefKey, SafeBrowsing.prefKeyDefaultValue, BraveShieldState.kSafeBrowsing)
        case toggleBlockScripts:
            setKeys(kPrefKeyNoScriptOn, false, BraveShieldState.kNoscript)
        case toggleHttpse:
            setKeys(HttpsEverywhere.prefKey, HttpsEverywhere.prefKeyDefaultValue, BraveShieldState.kHTTPSE)
        case shieldToggle:
            setKeys("", false, BraveShieldState.kAllOff)
        case toggleBlockFingerprinting:
            setKeys(kPrefKeyFingerprintProtection, false, BraveShieldState.kFPProtection)
        default:
            break
        }

    }

    override func showPanel(showing: Bool, parentSideConstraints: [Constraint?]?) {
        if showing {
            siteName.text = BraveApp.getCurrentWebView()?.URL?.normalizedHost() ?? "-"

            let state = BraveShieldState.getStateForDomain(siteName.text ?? "")
            shieldToggle.on = !(state?.isAllOff() ?? false)
            toggleBlockAds.on = state?.isOnAdBlockAndTp() ?? AdBlocker.singleton.isNSPrefEnabled
            toggleHttpse.on = state?.isOnHTTPSE() ?? HttpsEverywhere.singleton.isNSPrefEnabled
            toggleBlockMalware.on = state?.isOnSafeBrowsing() ?? SafeBrowsing.singleton.isNSPrefEnabled
            toggleBlockScripts.on = state?.isOnScriptBlocking() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyNoScriptOn) ?? false)
            toggleBlockFingerprinting.on = state?.isOnFingerprintProtection() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyFingerprintProtection) ?? false)
        }

        super.showPanel(showing, parentSideConstraints: parentSideConstraints)

        if showing {
            headerContainer.snp_remakeConstraints { make in
                make.top.left.right.equalTo(headerContainer.superview!)
                make.height.equalTo(44 + spaceForStatusBar())
            }
        }
    }

    func setShieldBlockedStats(shieldStats: ShieldBlockedStats) {
        statAdsBlocked.text = String(shieldStats.abAndTp)
        statHttpsUpgrades.text = String(shieldStats.httpse)
        statFPBlocked.text = String(shieldStats.fp)
        statScriptsBlocked.text = String(shieldStats.js)
    }
}
