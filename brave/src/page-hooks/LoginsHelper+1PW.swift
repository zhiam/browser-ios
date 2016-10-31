import Foundation

import Shared
import Storage
import Deferred

let tagForManagerButton = NSUUID().hash
var noPopupOnSites: [String] = []

let kPrefName3rdPartyPasswordShortcutEnabled = "thirdPartyPasswordShortcutEnabled"

typealias ThirdPartyPasswordManagerType = (displayName: String, cellLabel: String, prefId: Int)
struct ThirdPartyPasswordManagers {
    static let UseBuiltInInstead:ThirdPartyPasswordManagerType = (displayName: "Don't use", cellLabel: "", prefId: 0)
    static let OnePassword:ThirdPartyPasswordManagerType = (displayName: "1Password", cellLabel: "1Password", prefId: 1)
    static let LastPass:ThirdPartyPasswordManagerType = (displayName: "LastPass", cellLabel: "LastPass", prefId: 2)
}

extension LoginsHelper {
    func thirdPartyHelper(enabled: (Bool)->Void) {
        BraveApp.is3rdPartyPasswordManagerInstalled(refreshLookup: false).upon {
            result in
            if !result {
                enabled(false)
            }
            enabled(true)
        }
    }

    func passwordManagerButtonSetup(callback: (Bool)->Void) {
        thirdPartyHelper { (enabled) in
            if !enabled {
                return // No 3rd party password manager installed
            }

            postAsyncToMain {
                [weak self] in
                let result = self?.browser?.webView?.stringByEvaluatingJavaScriptFromString("document.querySelectorAll(\"input[type='password']\").length !== 0")
                if let ok = result, me = self where ok == "true" {
                    let show = me.shouldShowPasswordManagerButton()
                    if UIDevice.currentDevice().userInterfaceIdiom != .Pad {
                        me.addPasswordManagerButtonKeyboardAccessory()
                    }
                    callback(show)
                }
                else {
                    callback(false)
                }
            }
        }
    }

    func getKeyboardAccessory() -> UIView? {
        let keyboardWindow: UIWindow = UIApplication.sharedApplication().windows[1] as UIWindow
        let accessoryView: UIView = findFormAccessory(keyboardWindow)
        if accessoryView.description.hasPrefix("<UIWebFormAccessory") {
            return accessoryView.viewWithTag(tagForManagerButton)
        }
        return nil
    }

    func hideKeyboardAccessory() {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return
        }
        getKeyboardAccessory()?.removeFromSuperview()
    }
    
    func findFormAccessory(vw: UIView) -> UIView {
        if vw.description.hasPrefix("<UIWebFormAccessory") {
            return vw
        }
        for i in (0  ..< vw.subviews.count) {
            let subview = vw.subviews[i] as UIView;
            if subview.subviews.count > 0 {
                let subvw = self.findFormAccessory(subview)
                if subvw.description.hasPrefix("<UIWebFormAccessory") {
                    return subvw
                }
            }
        }
        return UIView()
    }

    func shouldShowPasswordManagerButton() -> Bool {
        if !OnePasswordExtension.sharedExtension().isAppExtensionAvailable() {
            return false
        }

        // If user explicitly selected to use the built-in autofill, don't add the PW manager button
        if let setting = ThirdPartyPasswordManagerSetting.currentSetting where setting == ThirdPartyPasswordManagers.UseBuiltInInstead {
            return false
        }

        let windows = UIApplication.sharedApplication().windows.count
        if windows < 2 {
            return false
        }

        return true
    }

    func addPasswordManagerButtonKeyboardAccessory() {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return
        }

        let keyboardWindow: UIWindow = UIApplication.sharedApplication().windows[1] as UIWindow
        let accessoryView: UIView = findFormAccessory(keyboardWindow)
        if !accessoryView.description.hasPrefix("<UIWebFormAccessory") {
            return
        }
        
        if let old = accessoryView.viewWithTag(tagForManagerButton) {
            old.removeFromSuperview()
        }

        let lastPassSelected = ThirdPartyPasswordManagerSetting.currentSetting?.prefId ?? 0 == ThirdPartyPasswordManagers.LastPass.prefId
        let image = lastPassSelected ? UIImage(named: "passhelper_lastpass") : UIImage(named: "passhelper_1pwd")

        let managerButton = UIButton(frame: CGRectMake(0, 0, 44, 44))
        managerButton.tag = tagForManagerButton
        managerButton.tintColor = UIColor(white: 0.0, alpha: 0.3)
        managerButton.setImage(image?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        managerButton.addTarget(self, action: #selector(LoginsHelper.onExecuteTapped), forControlEvents: .TouchUpInside)
        managerButton.sizeToFit()
        accessoryView.addSubview(managerButton)
        
        var managerButtonFrame = managerButton.frame
        managerButtonFrame.origin.x = rint((CGRectGetWidth(UIScreen.mainScreen().bounds) - CGRectGetWidth(managerButtonFrame)) / 2.0)
        managerButtonFrame.origin.y = rint((CGRectGetHeight(accessoryView.bounds) - CGRectGetHeight(managerButtonFrame)) / 2.0)
        managerButton.frame = managerButtonFrame
    }

    // recurse through items until the 1pw/lastpass share item is found
    private func selectShareItem(view: UIView, shareItemName: String) -> Bool {
        if shareItemName.characters.count == 0 {
            return false
        }

        for subview in view.subviews {
            if subview.description.contains("UICollectionViewControllerWrapperView") && subview.subviews.first?.subviews.count > 1 {
                let wrapperCell = subview.subviews.first?.subviews[1] as? UICollectionViewCell
                if let collectionView = wrapperCell?.subviews.first?.subviews.first?.subviews.first as? UICollectionView {

                    // As a safe upper bound, just look at 10 items max
                    for i in 0..<10 {
                        let indexPath = NSIndexPath(forItem: i, inSection: 0)
                        let suspectCell = collectionView.cellForItemAtIndexPath(indexPath)
                        if suspectCell == nil {
                            break;
                        }
                        if suspectCell?.subviews.first?.subviews.last?.description.contains(shareItemName) ?? false {
                            collectionView.delegate?.collectionView?(collectionView, didSelectItemAtIndexPath:indexPath)
                            return true
                        }
                    }

                    return false
                }
            }
            let found = selectShareItem(subview, shareItemName: shareItemName)
            if found {
                return true
            }
        }
        return false
    }

    // MARK: Tap
    @objc func onExecuteTapped(sender: UIButton) {
        self.browser?.webView?.endEditing(true)

        let automaticallyPickPasswordShareItem = ThirdPartyPasswordManagerSetting.currentSetting != nil
        let isIPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad

        if automaticallyPickPasswordShareItem {
            UIActivityViewController.hackyHideSharePickerOn(true)

            UIView.animateWithDuration(0.2) {
                getApp().braveTopViewController.view.alpha = 0.5
            }
        }

        let passwordHelper = OnePasswordExtension.sharedExtension()
        passwordHelper.dismissBlock = { action in
            if action.contains("onepassword") {
                ThirdPartyPasswordManagerSetting.currentSetting = ThirdPartyPasswordManagers.OnePassword
            }
            else if action.contains("lastpass") {
                ThirdPartyPasswordManagerSetting.currentSetting = ThirdPartyPasswordManagers.LastPass
            }
            else {
                ThirdPartyPasswordManagerSetting.currentSetting = ThirdPartyPasswordManagers.UseBuiltInInstead
            }
            
            BraveApp.getPrefs()?.setInt(Int32(ThirdPartyPasswordManagerSetting.currentSetting?.prefId ?? 0), forKey: kPrefName3rdPartyPasswordShortcutEnabled)
        }

        passwordHelper.shareDidAppearBlock = {
            if !automaticallyPickPasswordShareItem {
                return
            }

            guard let itemToLookFor = ThirdPartyPasswordManagerSetting.currentSetting?.cellLabel else { return }
            let found = self.selectShareItem(getApp().window!, shareItemName: itemToLookFor)

            if !found {
                UIView.animateWithDuration(0.2) {
                    getApp().braveTopViewController.view.alpha = 1.0
                }

                if isIPad {
                    UIActivityViewController.hackyDismissal()

                    BraveApp.showErrorAlert(title: "Password shortcut error", error: "Make sure \(itemToLookFor) is enabled in the Share menu")
                }
                // Just show the regular share screen, this isn't a fatal problem on iPhone
                UIActivityViewController.hackyHideSharePickerOn(false)
            }
        }

        passwordHelper.fillItemIntoWebView(browser!.webView!, forViewController: getApp().browserViewController, sender: sender, showOnlyLogins: true) { (success, error) -> Void in
            if automaticallyPickPasswordShareItem {
                UIActivityViewController.hackyHideSharePickerOn(false)

                UIView.animateWithDuration(0.1) {
                    getApp().braveTopViewController.view.alpha = 1.0
                }
            }

            if !success {
                print("Failed to fill into webview: <\(error)>")
            }
        }
    }
}
