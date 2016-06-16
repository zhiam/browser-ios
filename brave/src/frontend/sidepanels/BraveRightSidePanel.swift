/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import SnapKit

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
    var views_toggles = [UISwitch]()
    var views_labels = [UILabel]()

    let togglesContainer = UIView()
    let headerContainer = UIView()

    override var canShow: Bool {
        let site = BraveApp.getCurrentWebView()?.URL?.normalizedHost()
        return site != nil && getApp().browserViewController.homePanelController == nil
    }

    override func viewDidLoad() {
        isLeftSidePanel = false
        super.viewDidLoad()
    }

    override func setupContainerViewSize() {
        containerView.frame = CGRectMake(0, 0, CGFloat(BraveUX.WidthOfSlideOut), 450)
        viewAsScrollView().contentSize = CGSizeMake(containerView.frame.width, containerView.frame.height)
    }

    override func setupUIElements() {
        super.setupUIElements()
        
        viewAsScrollView().scrollEnabled = true

        togglesContainer.backgroundColor = UIColor.init(white: 238.0/255.0, alpha: 1.0)
        view.backgroundColor = togglesContainer.backgroundColor
        containerView.backgroundColor = togglesContainer.backgroundColor

        func setupHeaderSection() {
            headerContainer.backgroundColor = UIColor(white: 77/255.0, alpha: 1.0)
            
            containerView.addSubview(headerContainer)
            headerContainer.snp_makeConstraints {
                make in
                make.top.left.right.equalTo(headerContainer.superview!)
                make.height.equalTo(130)
            }

            heading.text = "Brave Shields for"
            heading.textColor = UIColor.whiteColor()
            heading.font = UIFont.boldSystemFontOfSize(18)
            siteName.textColor = UIColor.whiteColor()
            siteName.font = UIFont.boldSystemFontOfSize(22)

            let down = UILabel()
            down.text = "Down"
            let up = UILabel()
            up.text = "Up"

            [heading, siteName, up, down, shieldToggle].forEach { headerContainer.addSubview($0) }
            heading.snp_makeConstraints {
                make in
                make.left.equalTo(heading.superview!).inset(20)
                make.bottom.equalTo(siteName.snp_top).inset(-2)
            }

            siteName.snp_makeConstraints {
                make in
                make.left.equalTo(heading)
                make.bottom.equalTo(shieldToggle.snp_top).inset(-8)
            }

            [down, up].forEach {
                $0.textColor = UIColor.whiteColor()
                $0.font = UIFont.boldSystemFontOfSize(14)
            }

            down.snp_makeConstraints {
                make in
                make.left.equalTo(down.superview!).inset(22)
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
                make.bottom.equalTo(shieldToggle.superview!).inset(20)
            }
            shieldToggle.onTintColor = BraveUX.BraveOrange
            shieldToggle.addTarget(self, action: #selector(switchToggled(_:)), forControlEvents: .ValueChanged)

        }
        setupHeaderSection()

        containerView.addSubview(togglesContainer)

        togglesContainer.snp_makeConstraints {
            make in
            make.left.right.equalTo(containerView)
            make.top.equalTo(headerContainer.snp_bottom)
            make.bottom.equalTo(containerView)
        }

        views_toggles = [toggleBlockAds, toggleHttpse, toggleBlockMalware, toggleBlockScripts, toggleBlockFingerprinting]
        views_toggles.forEach { togglesContainer.addSubview($0) }
        views_labels = [toggleBlockAdsTitle, toggleHttpseTitle, toggleBlockMalwareTitle, toggleBlockScriptsTitle, toggleBlockFingerprintingTitle]
        let labelTitles = ["Block Ads & Tracking", "HTTPS Everywhere", "Block Phishing", "Block Scripts", "Fingerprinting\nProtection"]
        views_labels.forEach { togglesContainer.addSubview($0) }

        func layoutSwitch(item: UIView, below: UIView?) {
            item.snp_makeConstraints {
                make in
                make.left.equalTo(item.superview!.snp_left).inset(14)
                if let below = below {
                    make.top.equalTo(below.snp_bottom).offset(22)
                } else {
                    make.top.equalTo(item.superview!.snp_top).offset(22)
                }
            }
        }

        var i = 0
        views_toggles.forEach { item in
            item.onTintColor = BraveUX.BraveOrange
            item.addTarget(self, action: #selector(switchToggled(_:)), forControlEvents: .ValueChanged)
            layoutSwitch(item, below: i > 0 ? views_toggles[i - 1] : nil)
            i += 1
        }

        i = 0
        views_labels.forEach { item in
            item.text = labelTitles[i]
            item.snp_makeConstraints {
                make in
                make.left.equalTo(views_toggles[i].snp_right).offset(10)
                make.centerY.equalTo(views_toggles[i].snp_centerY)
            }
            i += 1
        }
        toggleBlockFingerprintingTitle.lineBreakMode = .ByWordWrapping
        toggleBlockFingerprintingTitle.numberOfLines = 2
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
        siteName.text = BraveApp.getCurrentWebView()?.URL?.normalizedHost() ?? "-"

        let state = BraveShieldState.getStateForDomain(siteName.text ?? "")
        shieldToggle.on = !(state?.isAllOff() ?? false)
        toggleBlockAds.on = state?.isOnAdBlockAndTp() ?? AdBlocker.singleton.isNSPrefEnabled
        toggleHttpse.on = state?.isOnHTTPSE() ?? HttpsEverywhere.singleton.isNSPrefEnabled
        toggleBlockMalware.on = state?.isOnSafeBrowsing() ?? SafeBrowsing.singleton.isNSPrefEnabled
        toggleBlockScripts.on = state?.isOnScriptBlocking() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyNoScriptOn) ?? false)
        toggleBlockFingerprinting.on = state?.isOnFingerprintProtection() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyFingerprintProtection) ?? false)

        super.showPanel(showing, parentSideConstraints: parentSideConstraints)
    }
    
}


