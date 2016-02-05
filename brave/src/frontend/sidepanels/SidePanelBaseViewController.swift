/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import SnapKit

class SidePanelBaseViewController : UIViewController {

    var browser:BrowserViewController?

    // Wrap everything in a UIScrollView the view animation will not try to shrink the view
    // add subviews to containerView not self.view
    let containerView = UIView()

    // Set false for a right side panel
    var isLeftSidePanel = true


    var parentSideConstraints: [Constraint]?


    override func loadView() {
        self.view = UIScrollView(frame: UIScreen.mainScreen().bounds)
    }

    func viewAsScrollView() -> UIScrollView {
        return self.view as! UIScrollView
    }

    func setupContainerViewSize() {
        containerView.frame = CGRectMake(0, 0, CGFloat(BraveUX.WidthOfSlideOut), self.view.frame.height)
        viewAsScrollView().contentSize = CGSizeMake(containerView.frame.width, containerView.frame.height)
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupContainerViewSize()
    }

    override func viewDidLoad() {
        viewAsScrollView().scrollEnabled = false

        view.addSubview(containerView)
        setupContainerViewSize()
        containerView.backgroundColor = UIColor(white: 77/255.0, alpha: 1.0)

        view.hidden = true
    }

    func setupConstraints() {}

    func spaceForStatusBar() -> Double {
        let spacer = BraveApp.isIPhoneLandscape() ? 0.0 : 20.0
        return spacer
    }

    func verticalBottomPositionMainToolbar() -> Double {
        return Double(UIConstants.ToolbarHeight) + spaceForStatusBar()
    }

    func showPanel(showing: Bool, parentSideConstraints: [Constraint]? = nil) {
        if (parentSideConstraints != nil) {
            self.parentSideConstraints = parentSideConstraints
        }

        if (showing) {
            view.hidden = false
            setupConstraints()
        }
        view.layoutIfNeeded()

        let width = showing ? BraveUX.WidthOfSlideOut : 0
        let animation = {
            guard let superview = self.view.superview else { return }
            self.view.snp_remakeConstraints {
                make in
                if self.isLeftSidePanel {
                    make.bottom.left.top.equalTo(superview)
                } else {
                    make.bottom.right.top.equalTo(superview)
                }
                make.width.equalTo(width)
            }

            if let constraints = self.parentSideConstraints {
                for c in constraints {
                    c.updateOffset(self.isLeftSidePanel ? width : -width)
                }
            }
            superview.layoutIfNeeded()

            guard let topVC = getApp().rootViewController.visibleViewController else { return }
            topVC.setNeedsStatusBarAppearanceUpdate()
        }

        var percentComplete = Double(view.frame.width) / Double(BraveUX.WidthOfSlideOut)
        if showing {
            percentComplete = 1.0 - percentComplete
        }
        let duration = 0.2 * percentComplete
        UIView.animateWithDuration(duration, animations: animation)
        if (!showing) { // for reasons unknown, wheh put in a animation completion block, this is called immediately
            delay(duration) { self.view.hidden = true }
        }
    }

    func setHomePanelDelegate(delegate: HomePanelDelegate?) {}

}


