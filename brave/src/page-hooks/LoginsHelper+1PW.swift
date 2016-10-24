import Foundation

import Shared
import Storage
import Deferred

var iPadOffscreenView = UIView(frame: CGRectMake(3000,0,1,1))
let tagForManagerButton = 64682
var noPopupOnSites: [String] = []

let kPrefName3rdPartyPasswordShortcutEnabled = "thirdPartyPasswordShortcutEnabled"


struct ThirdPartyPasswordManagers {
    static let UseBuiltInInstead = (displayName: "Don't use", cellLabel: "", prefId: 0)
    static let OnePassword = (displayName: "1Password", cellLabel: "1Password", prefId: 1)
    static let LastPass = (displayName: "LastPass", cellLabel: "LastPass", prefId: 2)
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
    
    // MARK: Form Accessory
    
    func show() {
        thirdPartyHelper { (enabled) in
            if enabled == true {
                postAsyncToMain(0.1) {
                    [weak self] in
                    let result = self?.browser?.webView?.stringByEvaluatingJavaScriptFromString("document.querySelectorAll(\"input[type='password']\").length !== 0")
                    if let ok = result where ok == "true" {
                        self?.addPasswordManagerButton()
                    }
                }
            }
        }
    }
    
    func hide() {
        let keyboardWindow: UIWindow = UIApplication.sharedApplication().windows[1] as UIWindow
        let accessoryView: UIView = findFormAccessory(keyboardWindow)
        if accessoryView.description.hasPrefix("<UIWebFormAccessory") {
            if let manager = accessoryView.viewWithTag(tagForManagerButton) {
                manager.removeFromSuperview()
            }
        }
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
    
    func addPasswordManagerButton() {
        let windows = UIApplication.sharedApplication().windows.count
        if windows < 2 {
            return;
        }
        
        let keyboardWindow: UIWindow = UIApplication.sharedApplication().windows[1] as UIWindow
        let accessoryView: UIView = findFormAccessory(keyboardWindow)
        if accessoryView.description.hasPrefix("<UIWebFormAccessory") {
            if let old = accessoryView.viewWithTag(tagForManagerButton) {
                old.removeFromSuperview()
            }
            
            //
            var option: Int? = ThirdPartyPasswordManagerSetting.currentSetting?.prefId
            if option == nil || option == 0 {
                if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() {
                    option = ThirdPartyPasswordManagers.OnePassword.prefId
                }
            }
            
            let image: UIImage?
            switch option ?? 0 {
            case 1:
                image = UIImage(named: "passhelper_1pwd")
            case 2:
                image = UIImage(named: "passhelper_lastpass")
            default:
                return
            }
            
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
    }
    
    // MARK: Tap
    
    @objc func onExecuteTapped(sender: UIButton) {
        self.browser?.webView?.endEditing(true)
        
        let isIPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
        if isIPad && iPadOffscreenView.superview == nil {
            getApp().browserViewController.view.addSubview(iPadOffscreenView)
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
        passwordHelper.fillItemIntoWebView(browser!.webView!, forViewController: getApp().browserViewController, sender: sender, showOnlyLogins: true) { (success, error) -> Void in
            if isIPad {
                iPadOffscreenView.removeFromSuperview()
            } else {
                UIAlertController.hackyHideOn(false)
            }
            
            if success == false {
                print("Failed to fill into webview: <\(error)>")
            }
        }
        
        var found = false
        
        // recurse through items until the 1pw share item is found
        func selectShareItem(view: UIView, shareItemName: String) {
            if found || shareItemName.characters.count == 0 {
                return
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
                                found = true
                            }
                        }
                        
                        return
                    }
                }
                selectShareItem(subview, shareItemName: shareItemName)
            }
        }
        
        // The event loop needs to run for the share screen to reliably be showing, a delay of zero also works.
        postAsyncToMain(0.2) {
            guard let itemToLookFor = ThirdPartyPasswordManagerSetting.currentSetting?.cellLabel else { return }
            selectShareItem(getApp().window!, shareItemName: itemToLookFor)
            
            if !found {
                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                    UIActivityViewController.hackyDismissal()
                    iPadOffscreenView.removeFromSuperview()
                    BraveApp.getPrefs()?.setInt(0, forKey: kPrefName3rdPartyPasswordShortcutEnabled)
                    BraveApp.showErrorAlert(title: "Password shortcut error", error: "Can't find item named \(itemToLookFor)")
                } else {
                    // Just show the regular share screen, this isn't a fatal problem on iPhone
                    UIAlertController.hackyHideOn(false)
                }
            }
        }
    }
}
