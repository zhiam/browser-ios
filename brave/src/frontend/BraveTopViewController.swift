/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import SnapKit

let kNotificationLeftSlideOutClicked = "kNotificationLeftSlideOutClicked"
let kNotificationRightSlideOutClicked = "kNotificationRightSlideOutClicked"

class BraveTopViewController : UIViewController {
    var browser:BraveBrowserViewController
    var mainSidePanel:MainSidePanelViewController
    var rightSidePanel:BraveRightSidePanelViewController

    var clickDetectionView = UIButton()
    var leftConstraint: Constraint? = nil
    var rightConstraint: Constraint? = nil

    init(browser:BraveBrowserViewController) {
        self.browser = browser
        mainSidePanel = MainSidePanelViewController()
        rightSidePanel = BraveRightSidePanelViewController()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private func addVC(vc: UIViewController) {
        addChildViewController(vc)
        view.addSubview(vc.view)
        vc.didMoveToParentViewController(self)
    }

    override func viewDidLoad() {
        view.accessibilityLabel = "HighestView"
        view.backgroundColor = UIColor.blackColor()

        browser.view.accessibilityLabel = "BrowserView"

        addVC(browser)
        addVC(mainSidePanel)
        addVC(rightSidePanel)

        mainSidePanel.view.snp_makeConstraints {
            make in
            make.bottom.left.top.equalTo(view)
            make.width.equalTo(0)
        }

        rightSidePanel.view.snp_makeConstraints {
            make in
            make.bottom.right.top.equalTo(view)
            make.width.equalTo(0)
        }
        

        //    clickDetectionView.layer.shadowColor = UIColor.redColor().CGColor
        //    clickDetectionView.layer.shadowOffset = CGSizeMake(-4, 0)
        //    clickDetectionView.layer.shadowOpacity = 0.7
        //    clickDetectionView.layer.shadowRadius = 8.0

        clickDetectionView.backgroundColor = UIColor(white: 100/255, alpha: 0.1)

        setupBrowserConstraints(useTopLayoutGuide: true)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "leftSlideOutClicked:", name: kNotificationLeftSlideOutClicked, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "rightSlideOutClicked:", name: kNotificationRightSlideOutClicked, object: nil)

        clickDetectionView.addTarget(self, action: "dismissAllSidePanels:", forControlEvents: UIControlEvents.TouchUpInside)

        mainSidePanel.browser = browser
    }

    @objc func dismissAllSidePanels(button: UIButton) {
        if leftPanelShowing() {
            togglePanel(mainSidePanel)
        }
        if rightPanelShowing() {
            togglePanel(rightSidePanel)
        }
    }

    private func setupBrowserConstraints(useTopLayoutGuide useTopLayoutGuide: Bool) {
        browser.view.snp_remakeConstraints {
            make in
            make.bottom.equalTo(view)
            if useTopLayoutGuide {
                make.top.equalTo(snp_topLayoutGuideTop)
            } else {
                make.top.equalTo(view).inset(20)
            }
            if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
             //   make.width.equalTo(view.snp_width)
            } else {
                make.right.equalTo(view)
            }
            leftConstraint = make.left.equalTo(view).constraint
            rightConstraint = make.right.equalTo(view).constraint
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    func leftPanelShowing() -> Bool {
        return mainSidePanel.view.frame.width == CGFloat(BraveUX.WidthOfSlideOut)
    }

    func rightPanelShowing() -> Bool {
        return rightSidePanel.view.frame.width == CGFloat(BraveUX.WidthOfSlideOut)
    }

    override func prefersStatusBarHidden() -> Bool {
        if UIDevice.currentDevice().userInterfaceIdiom != .Phone {
            return super.prefersStatusBarHidden()
        }

        if BraveApp.isIPhoneLandscape() {
            return true
        }

        return leftPanelShowing() || rightPanelShowing()
    }

    func leftSlideOutClicked(_:NSNotification) {
        togglePanel(mainSidePanel)
    }

    func rightSlideOutClicked(_:NSNotification) {
        togglePanel(rightSidePanel)
    }

    func specialTouchEventHandling(touchPoint: CGPoint, phase: UITouchPhase ) {
   //     mainSidePanel.onTouchToHide(touchPoint, phase: phase)
    }

    func togglePanel(panel: SidePanelBaseViewController) {
        clickDetectionView.removeFromSuperview()
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone && panel.view.hidden {
            view.addSubview(clickDetectionView)
            clickDetectionView.snp_remakeConstraints {
                make in
                make.edges.equalTo(browser.view)
            }
            clickDetectionView.layoutIfNeeded()
        }
        panel.setHomePanelDelegate(self)
        panel.showPanel(panel.view.hidden, parentSideConstraints: [leftConstraint!, rightConstraint!])
    }

}

extension BraveTopViewController : HomePanelDelegate {
    func homePanelDidRequestToSignIn(homePanel: HomePanel) {}
    func homePanelDidRequestToCreateAccount(homePanel: HomePanel) {}
    func homePanel(homePanel: HomePanel, didSelectURL url: NSURL, visitType: VisitType) {
        print("selected \(url)")
        browser.urlBar.leaveOverlayMode()
        browser.tabManager.selectedTab?.loadRequest(NSURLRequest(URL: url))
        togglePanel(mainSidePanel)
    }
}