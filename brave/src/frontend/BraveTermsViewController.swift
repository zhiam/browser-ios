/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Foundation

protocol BraveTermsViewControllerDelegate {
    func braveTermsAcceptedTermsAndOptIn() -> Void
    func braveTermsAcceptedTermsAndOptOut() -> Void
    func dismissed()
}

class BraveTermsViewController: UIViewController {
    
    var delegate: BraveTermsViewControllerDelegate?
    
    private var braveLogo: UIImageView!
    private var termsLabel: UITextView!
    private var optLabel: UILabel!
    private var checkButton: UIButton!
    private var continueButton: UIButton!
    
    override func loadView() {
        super.loadView()
        
        braveLogo = UIImageView(image: UIImage(named: "braveLogoLarge"))
        braveLogo.contentMode = .Center
        view.addSubview(braveLogo)
        
        termsLabel = UITextView()
        termsLabel.backgroundColor = UIColor.clearColor()
        termsLabel.scrollEnabled = false
        termsLabel.selectable = true
        termsLabel.editable = false
        termsLabel.dataDetectorTypes = [.All]
        
        let attributedString = NSMutableAttributedString(string: NSLocalizedString("By using this application, you agree to Brave’s Terms of Use.", comment: ""))
        let linkRange = (attributedString.string as NSString).rangeOfString(NSLocalizedString("Terms of Use.", comment: ""))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center
        
        let fontAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont.systemFontOfSize(18.0, weight: UIFontWeightMedium),
            NSParagraphStyleAttributeName: paragraphStyle ]
        
        attributedString.addAttributes(fontAttributes, range: NSMakeRange(0, (attributedString.string.characters.count - 1)))
        attributedString.addAttribute(NSLinkAttributeName, value: "https://brave.com/terms_of_use.html", range: linkRange)
        
        let linkAttributes = [
            NSForegroundColorAttributeName: UIColor(red: 255/255.0, green: 80/255.0, blue: 0/255.0, alpha: 1.0) ]
        
        termsLabel.linkTextAttributes = linkAttributes
        termsLabel.attributedText = attributedString
        termsLabel.delegate = self
        view.addSubview(termsLabel)
        
        optLabel = UILabel()
        optLabel.text = NSLocalizedString("Help make Brave better by sending usage statistics and crash reports to us.", comment: "")
        optLabel.font = UIFont.systemFontOfSize(18.0, weight: UIFontWeightMedium)
        optLabel.textColor = UIColor(white: 1.0, alpha: 0.5)
        optLabel.numberOfLines = 0
        optLabel.lineBreakMode = .ByWordWrapping
        view.addSubview(optLabel)
        
        checkButton = UIButton(type: .Custom)
        checkButton.setImage(UIImage(named: "sharedata_uncheck"), forState: .Normal)
        checkButton.setImage(UIImage(named: "sharedata_check"), forState: .Selected)
        checkButton.addTarget(self, action: #selector(checkUncheck(_:)), forControlEvents: .TouchUpInside)
        checkButton.selected = true
        view.addSubview(checkButton)
        
        continueButton = UIButton(type: .System)
        continueButton.titleLabel?.font = UIFont.systemFontOfSize(18.0, weight: UIFontWeightMedium)
        continueButton.setTitle(NSLocalizedString("Accept & Continue", comment: ""), forState: .Normal)
        continueButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        continueButton.addTarget(self, action: #selector(acceptAndContinue(_:)), forControlEvents: .TouchUpInside)
        continueButton.backgroundColor = UIColor(red: 255/255.0, green: 80/255.0, blue: 0/255.0, alpha: 1.0)
        continueButton.layer.cornerRadius = 4.5
        continueButton.layer.masksToBounds = true
        view.addSubview(continueButton)
        
        continueButton.snp_makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-30)
            make.height.equalTo(40)
            
            let width = self.continueButton.sizeThatFits(CGSizeMake(CGFloat.max, CGFloat.max)).width
            make.width.equalTo(width + 40)
        }
        
        optLabel.snp_makeConstraints { (make) in
            make.centerX.equalTo(self.view).offset(36/2)
            
            let width = min(UIScreen.mainScreen().bounds.width * 0.65, 350)
            make.width.equalTo(width)
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                make.bottom.equalTo(continueButton.snp_top).offset(-60).priorityHigh()
            }
            else {
                make.bottom.lessThanOrEqualTo(continueButton.snp_top).offset(-60).priorityHigh()
            }
        }
        
        checkButton.snp_makeConstraints { (make) in
            make.left.equalTo(optLabel.snp_left).offset(-36)
            make.top.equalTo(optLabel.snp_top).offset(4).priorityHigh()
        }
        
        termsLabel.snp_makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            
            let width = min(UIScreen.mainScreen().bounds.width * 0.70, 350)
            make.width.equalTo(width)
            make.bottom.equalTo(optLabel.snp_top).offset(-35).priorityMedium()
        }
        
        braveLogo.snp_makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.top.equalTo(10)
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                make.bottom.equalTo(termsLabel.snp_top)
            }
            else {
                make.height.equalTo(UIScreen.mainScreen().bounds.width > UIScreen.mainScreen().bounds.height ? UIScreen.mainScreen().bounds.height : UIScreen.mainScreen().bounds.width)
            }
        }
        
        view.backgroundColor = UIColor(red: 63/255.0, green: 63/255.0, blue: 63/255.0, alpha: 1.0)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return
        }
        
        if toInterfaceOrientation == .LandscapeLeft || toInterfaceOrientation == .LandscapeRight {
            UIView.animateWithDuration(0.2, animations: { 
                self.braveLogo.alpha = 0.15
            })
        }
        else {
            UIView.animateWithDuration(0.2, animations: {
                self.braveLogo.alpha = 1.0
            })
        }
        
        self.view.setNeedsUpdateConstraints()
    }
    
    // MARK: Actions
    
    func checkUncheck(sender: UIButton) {
        sender.selected = !sender.selected
    }
    
    func acceptAndContinue(sender: UIButton) {
        if checkButton.selected {
            delegate?.braveTermsAcceptedTermsAndOptIn()
        }
        else {
            delegate?.braveTermsAcceptedTermsAndOptOut()
        }
        dismissViewControllerAnimated(false, completion: nil)
    }

    override func dismissViewControllerAnimated(flag: Bool, completion: (() -> Void)?) {
        super.dismissViewControllerAnimated(flag, completion: completion)
        delegate?.dismissed()
    }
}

extension BraveTermsViewController: UITextViewDelegate {
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        return true
    }
}
