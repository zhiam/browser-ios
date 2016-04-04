import Foundation

import OnePasswordExtension

let iPadOffscreenView = UIView(frame: CGRectMake(3000,0,1,1))
let tagFor1PwSnackbar = 8675309

extension LoginsHelper {
    func registerPageListenersFor1PW() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "hideOnPageChange", name: kNotificationPageUnload, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "checkOnPageLoaded", name: BraveWebView.kNotificationWebViewLoadCompleteOrFailed, object: nil)
    }

    func onePasswordSnackbar() {
        if !OnePasswordExtension.sharedExtension().isAppExtensionAvailable() {
            return
        }

        if let snackBar = snackBar {
            if snackBar.tag == tagFor1PwSnackbar && snackBar.superview != nil {
                return // already have a 1PW snackbar showing
            }
            browser?.removeSnackbar(snackBar)
        }

        snackBar = SnackBar(attrText: NSAttributedString(string: "Sign in with 1Password"),
                            img: UIImage(named: "onepassword-button"),
                            buttons: [])
        snackBar!.tag = tagFor1PwSnackbar
        let button = UIButton()
        button.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        snackBar!.addSubview(button)
        button.addTarget(self, action: "onePwTapped", forControlEvents: .TouchUpInside)
        browser?.addSnackbar(snackBar!)
    }

    @objc func checkOnPageLoaded() {
        let result = browser?.webView?.stringByEvaluatingJavaScriptFromString("document.querySelectorAll(\"input[type='password']\").length !== 0")
        if let ok = result where ok == "true" {
            onePasswordSnackbar()
        }
    }

    @objc func hideOnPageChange() {
        if let snackBar = snackBar where snackBar.tag == tagFor1PwSnackbar {
            browser?.removeSnackbar(snackBar)
        }
    }

    @objc func onePwTapped() {
        UIAlertController.hackyHideOn(true)
        let sender:UIView = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? iPadOffscreenView : snackBar!

        if UIDevice.currentDevice().userInterfaceIdiom == .Pad && iPadOffscreenView.superview == nil {
            getApp().browserViewController.view.addSubview(iPadOffscreenView)
        }

        OnePasswordExtension.sharedExtension().fillItemIntoWebView(browser!.webView!, forViewController: getApp().browserViewController, sender: sender, showOnlyLogins: true) { (success, error) -> Void in
            iPadOffscreenView.removeFromSuperview()
            UIAlertController.hackyHideOn(false)

            if success == false {
                print("Failed to fill into webview: <\(error)>")
            }
        }

        var foundShareSection = false

        // recurse through items until the 1pw share item is found
        func selectOnePasswordShareItem(v: UIView) {
            if foundShareSection {
                return
            }

            for i in v.subviews {
                if i.description.contains("UICollectionViewControllerWrapperView") {
                    let wrapperCell = i.subviews.first?.subviews[1] as? UICollectionViewCell
                    if let collectionView = wrapperCell?.subviews.first?.subviews.first?.subviews.first as? UICollectionView {

                        foundShareSection = true

                        let indexPath = NSIndexPath(forItem: 0, inSection: 0)
                        let suspectCell = collectionView.cellForItemAtIndexPath(indexPath)
                        if suspectCell?.subviews.first?.subviews.last?.description.contains("1Password") ?? false {
                            collectionView.delegate?.collectionView?(collectionView, didSelectItemAtIndexPath:indexPath)
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
        }
    }
}
