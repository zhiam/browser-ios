import Foundation

import OnePasswordExtension
import Shared
import Storage
import Deferred

var iPadOffscreenView = UIView(frame: CGRectMake(3000,0,1,1))
let tagFor1PwSnackbar = 8675309
var noPopupOnSites: [String] = []

let kPrefNameOnePasswordShortcutEnabled = "onepassword-shortcut"

extension LoginsHelper {
    func registerPageListenersFor1PW() {
        guard let wv = browser?.webView else { return }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "hideOnPageChange:", name: kNotificationPageUnload, object: wv)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "checkOnPageLoaded:", name: BraveWebView.kNotificationWebViewLoadCompleteOrFailed, object: wv)
    }

    func onePasswordSnackbar() {
        let isEnabled = BraveApp.getPrefs()?.boolForKey(kPrefNameOnePasswordShortcutEnabled) ?? true
        if !BraveApp.isOnePasswordInstalled(refreshLookup: false) || !isEnabled {
            return
        }

        guard let url = browser?.webView?.URL else { return }
        isInNoShowList(url).upon {
            [weak self]
            result in

             #if PW_DB
                // Turn Cursor rows, into array of matching rows. Ugly, surely I can write this cleaner
                if result.map({$0.asArray()}).successValue?.count > 0 {
                    return
                }
            #else
                if result {
                    return
                }
            #endif

            ensureMainThread {
                [weak self] in
                guard let safeSelf = self else { return }
                if let snackBar = safeSelf.snackBar {
                    if safeSelf.browser?.bars.map({ $0.tag }).indexOf(tagFor1PwSnackbar) != nil {
                        return // already have a 1PW snackbar active for this tab
                    }

                    safeSelf.browser?.removeSnackbar(snackBar)
                }

                safeSelf.snackBar = SnackBar(attrText: NSAttributedString(string: "Sign in with 1Password"), img: UIImage(named: "onepassword-button"), buttons: [])
                safeSelf.snackBar!.tag = tagFor1PwSnackbar
                let button = UIButton()
                button.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                safeSelf.snackBar!.addSubview(button)
                button.addTarget(self, action: "onePwTapped", forControlEvents: .TouchUpInside)

                let close = UIButton(frame: CGRectMake(safeSelf.snackBar!.frame.width - 40, 0, 40, 40))
                close.setImage(UIImage(named: "stop")!, forState: .Normal)
                close.addTarget(self, action: "closeOnePwTapped", forControlEvents: .TouchUpInside)
                close.tintColor = UIColor.blackColor()
                close.autoresizingMask = [.FlexibleLeftMargin]
                safeSelf.snackBar!.addSubview(close)

                safeSelf.browser?.addSnackbar(safeSelf.snackBar!)
            }
        }

    }

    @objc func closeOnePwTapped() {
        if let s = snackBar {
            self.browser?.removeSnackbar(s)

            guard let host = browser?.webView?.URL?.hostWithGenericSubdomainPrefixRemoved() else { return }
            noPopupOnSites.append(host)
            #if PW_DB
                getApp().profile!.db.write("INSERT INTO \(TableOnePasswordNoPopup) (domain) VALUES (?)", withArgs: [host])
            #endif
        }
    }

    @objc func checkOnPageLoaded(notification: NSNotification) {
        if notification.object !== browser?.webView {
            return
        }
        delay(0.1) {
            // TODO: This is only needed for private browsing, as a fallback because the logins detection isn't injected. Fix this.
            let result = self.browser?.webView?.stringByEvaluatingJavaScriptFromString("document.querySelectorAll(\"input[type='password']\").length !== 0")
            if let ok = result where ok == "true" {
                self.onePasswordSnackbar()
            }
        }
    }

    @objc func hideOnPageChange(notification: NSNotification) {
        if notification.object !== browser?.webView {
            return
        }
        if let snackBar = snackBar where snackBar.tag == tagFor1PwSnackbar {
            browser?.removeSnackbar(snackBar)
        }
    }

    @objc func onePwTapped() {
        browser?.removeSnackbar(snackBar!)
        let isIPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad

        if !isIPad {
            UIAlertController.hackyHideOn(true)
        }

        let sender:UIView = isIPad ? iPadOffscreenView : snackBar!

        if isIPad && iPadOffscreenView.superview == nil {
            getApp().browserViewController.view.addSubview(iPadOffscreenView)
        }

        OnePasswordExtension.sharedExtension().fillItemIntoWebView(browser!.webView!, forViewController: getApp().browserViewController, sender: sender, showOnlyLogins: true) { (success, error) -> Void in
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
        func selectOnePasswordShareItem(v: UIView) {
            if found {
                return
            }

            for i in v.subviews {
                if i.description.contains("UICollectionViewControllerWrapperView") {
                    let wrapperCell = i.subviews.first?.subviews[1] as? UICollectionViewCell
                    if let collectionView = wrapperCell?.subviews.first?.subviews.first?.subviews.first as? UICollectionView {

                        let indexPath = NSIndexPath(forItem: 0, inSection: 0)
                        let suspectCell = collectionView.cellForItemAtIndexPath(indexPath)
                        if suspectCell?.subviews.first?.subviews.last?.description.contains("1Password") ?? false {
                            collectionView.delegate?.collectionView?(collectionView, didSelectItemAtIndexPath:indexPath)
                            found = true
                        }
                        return
                    }
                }
                selectOnePasswordShareItem(i)
            }
        }
        delay(0.2) {
            // The event loop needs to run for the share screen to reliably be showing, a delay of zero also works.
            selectOnePasswordShareItem(getApp().window!)

            if !found {
                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                    UIActivityViewController.hackyDismissal()
                    iPadOffscreenView.removeFromSuperview()
                    BraveApp.getPrefs()?.setBool(false, forKey: kPrefNameOnePasswordShortcutEnabled)
                    BraveApp.showErrorAlert(title: "1Password shortcut error", error: "Disabling due to internal error. Please report this problem to support@brave.com.")
                } else {
                    // Just show the regular share screen, this isn't a fatal problem on iPhone
                    UIAlertController.hackyHideOn(false)
                }
            }
        }
    }

    #if PW_DB
    func isInNoShowList(url: NSURL)  -> Deferred<Maybe<Cursor<Bool>>>  {
        let host = url.hostWithGenericSubdomainPrefixRemoved()
        let sql = "SELECT domain from \(TableOnePasswordNoPopup) WHERE domain = ?"
        return getApp().profile!.db.runQuery(sql, args: [host], factory: { _ in
            return true
        })

    }
    #endif

    // Using a DB-backed storage for this is under consideration. ( #if PW_DB sections )
    // Use a similar Deferred-style so switching to the DB method is seamless
    func isInNoShowList(url: NSURL)  -> Deferred<Bool>  {
        let deferred = Deferred<Bool>()
        delay(0) {
            var result = false
            if let host = url.hostWithGenericSubdomainPrefixRemoved() {
                result = noPopupOnSites.contains(host)
            }
            deferred.fill(result)
        }
        return deferred
    }
}
