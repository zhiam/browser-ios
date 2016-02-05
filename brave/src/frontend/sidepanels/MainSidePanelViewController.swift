/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import SnapKit

class MainSidePanelViewController : SidePanelBaseViewController {

    let bookmarks = BookmarksPanel()
    let history = HistoryPanel()

    var bookmarksButton = UIButton()
    var historyButton = UIButton()

    let topButtonsView = UIView()
    let addBookmarkButton = UIButton()

    //let triangleViewContainer = UIView()
    let triangleView = UIImageView()

    let tabTitleViewContainer = UIView()
    let tabTitleView = UILabel()


    override func viewDidLoad() {
        super.viewDidLoad()

        tabTitleViewContainer.backgroundColor = UIColor.whiteColor()
        tabTitleView.textColor = self.view.tintColor
        bookmarks.profile = getApp().profile
        history.profile = getApp().profile

        containerView.addSubview(topButtonsView)

        containerView.addSubview(tabTitleViewContainer)
        tabTitleViewContainer.addSubview(tabTitleView)
        topButtonsView.addSubview(triangleView)
        topButtonsView.addSubview(bookmarksButton)
        topButtonsView.addSubview(historyButton)
        topButtonsView.addSubview(addBookmarkButton)

        triangleView.image = UIImage(named: "triangle-nub")
        triangleView.contentMode = UIViewContentMode.Center
        triangleView.alpha = 0.9

        bookmarksButton.setImage(UIImage(named: "bookmarklist"), forState: .Normal)
        bookmarksButton.addTarget(self, action: "showBookmarks", forControlEvents: .TouchUpInside)
        bookmarksButton.accessibilityLabel = NSLocalizedString("Show Bookmarks", comment: "Button to show the bookmarks list")

        historyButton.setImage(UIImage(named: "history"), forState: .Normal)
        historyButton.addTarget(self, action: "showHistory", forControlEvents: .TouchUpInside)
        historyButton.accessibilityLabel = NSLocalizedString("Show History", comment: "Button to show the history list")

        addBookmarkButton.addTarget(self, action: "addBookmark", forControlEvents: .TouchUpInside)
        addBookmarkButton.setImage(UIImage(named: "bookmark"), forState: .Normal)
        addBookmarkButton.accessibilityLabel = NSLocalizedString("Add Bookmark", comment: "Button to add a bookmark")

        bookmarksButton.tintColor = BraveUX.ActionButtonTintColor
        historyButton.tintColor = BraveUX.ActionButtonTintColor
        addBookmarkButton.tintColor = UIColor.whiteColor()

        containerView.addSubview(history.view)
        containerView.addSubview(bookmarks.view)

        showBookmarks()

        bookmarks.view.hidden = false

        containerView.bringSubviewToFront(topButtonsView)

    }

    func addBookmark() {
        guard let tab = browser?.tabManager.selectedTab,
            let url = tab.displayURL?.absoluteString else {
                return
        }

        browser?.addBookmark(url, title: tab.title)
        showBookmarks()

        delay(0.1) {
            self.bookmarks.reloadData()
        }
    }

    override func setupConstraints() {
        topButtonsView.snp_remakeConstraints {
            make in
            make.top.equalTo(containerView).offset(spaceForStatusBar())
            make.left.right.equalTo(containerView)
            make.height.equalTo(44.0)
        }

        historyButton.snp_remakeConstraints {
            make in
            make.bottom.equalTo(self.topButtonsView)
            make.height.equalTo(UIConstants.ToolbarHeight)
            make.centerX.equalTo(self.topButtonsView).dividedBy(2.0)
        }

        bookmarksButton.snp_remakeConstraints {
            make in
            make.bottom.equalTo(self.topButtonsView)
            make.height.equalTo(UIConstants.ToolbarHeight)
            make.centerX.equalTo(self.topButtonsView)
        }

        addBookmarkButton.snp_remakeConstraints {
            make in
            make.bottom.equalTo(self.topButtonsView)
            make.height.equalTo(UIConstants.ToolbarHeight)
            make.centerX.equalTo(self.topButtonsView).multipliedBy(1.5)
        }

        tabTitleViewContainer.snp_remakeConstraints {
            make in
            make.right.left.equalTo(containerView)
            make.top.equalTo(topButtonsView.snp_bottom)
            make.height.equalTo(44.0)
        }

        tabTitleView.snp_remakeConstraints {
            make in
            make.right.top.bottom.equalTo(tabTitleViewContainer)
            make.left.lessThanOrEqualTo(containerView).inset(24)
        }

        bookmarks.view.snp_remakeConstraints { make in
            make.left.right.bottom.equalTo(containerView)
            make.top.equalTo(tabTitleView.snp_bottom)
        }

        history.view.snp_remakeConstraints { make in
            make.left.right.bottom.equalTo(containerView)
            make.top.equalTo(tabTitleView.snp_bottom)
        }
    }

    func showBookmarks() {
        tabTitleView.text = "Bookmarks"
        history.view.hidden = true
        bookmarks.view.hidden = false
        moveTabIndicator(bookmarksButton)
    }

    func showHistory() {
        tabTitleView.text = "History"
        bookmarks.view.hidden = true
        history.view.hidden = false
        moveTabIndicator(historyButton)
    }

    func moveTabIndicator(button: UIButton) {
        triangleView.snp_remakeConstraints {
            make in
            make.width.equalTo(button)
            make.height.equalTo(6)
            make.left.equalTo(button)
            make.top.equalTo(button.snp_bottom)
        }
    }

    override func setHomePanelDelegate(delegate: HomePanelDelegate?) {
        bookmarks.homePanelDelegate = delegate
        history.homePanelDelegate = delegate
        if (delegate != nil) {
            bookmarks.reloadData()
            history.reloadData()
        }
    }

    var loc = CGFloat(-1)
    func onTouchToHide(touchPoint: CGPoint, phase: UITouchPhase) {
        if view.hidden {
            return
        }

        let isFullWidth = fabs(view.frame.width - CGFloat(BraveUX.WidthOfSlideOut)) < 0.5
        
        func complete() {
            if isFullWidth {
                loc = CGFloat(-1)
                return
            }
            
            let shouldShow = view.frame.width / CGFloat(BraveUX.WidthOfSlideOut) > CGFloat(BraveUX.PanelClosingThresholdWhenDragging)
            if shouldShow {
                showPanel(true)
            } else {
                setHomePanelDelegate(nil)
                showPanel(false)
            }
        }
        
        let isOnEdge = fabs(touchPoint.x - view.frame.width) < 10
        if !isOnEdge && loc < 0 && phase != .Began {
            return
        }
        
        switch phase {
        case .Began:  // A finger touched the screen
            loc = isOnEdge ? touchPoint.x : CGFloat(-1)
            break
        case .Moved, .Stationary:
            if loc < 0 || touchPoint.x > loc {
                complete()
                return
            }
            
            view.snp_remakeConstraints {
                make in
                make.bottom.left.top.equalTo(self.view.superview!)
                make.width.equalTo(CGFloat(BraveUX.WidthOfSlideOut) - (loc - touchPoint.x))
            }
            self.view.layoutIfNeeded()
            break
        case .Ended, .Cancelled:
            complete()
            break
        }
    }

}


