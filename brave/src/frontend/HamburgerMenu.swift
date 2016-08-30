class HamburgerMenu : UIViewController {
    let atBottom: Bool
    let height = CGFloat(64)
    let width = CGFloat(320)
    let parent: UIView
    let parentButton: UIView
    let parentButtonTint: UIColor

    let blueColor = UIColor(colorLiteralRed: 0/255.0, green: 118/255.0, blue: 255/255.0, alpha: 1.0)
    var isWebPage = false
    let itemsPerRow = 4

    var collectionView:UICollectionView!

    let titles = [ NSLocalizedString("Find in Page", comment: "button"),
                   NSLocalizedString("Desktop Site in new tab", comment: "button"),
                   NSLocalizedString("Share", comment: "button"),
                   NSLocalizedString("App Settings", comment: "button")]

    let images = ["menu-FindInPage", "menu-RequestDesktopSite", "menu-Send", "menu-Settings"]

    enum ButtonAction : Int {
        case find
        case desktopSite
        case share
        case settings
    }

    init(atBottom: Bool, parent: UIView, parentButton: UIView) {
        self.atBottom = atBottom
        self.parent = parent
        self.parentButton = parentButton
        self.parentButtonTint = parentButton.tintColor
        super.init(nibName: nil, bundle: nil)

        if let tab = getApp().tabManager.selectedTab, _ = tab.displayURL {
            isWebPage = true
        }

        parentButton.tintColor = blueColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        close()
    }

    func close() {
        view.removeFromSuperview()
        removeFromParentViewController()
        parentButton.tintColor = parentButtonTint
    }

    override func viewDidLoad() {
        let x = parent.frame.width * 0.5 - width * 0.5
        let y = parent.frame.height - UIConstants.ToolbarHeight - height
        view.frame = CGRect(x: x, y: y, width: width, height: height)
        view.backgroundColor = UIColor.clearColor()

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 0, right: 4)
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: width, height: height), collectionViewLayout: layout)

        view.addSubview(collectionView)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.registerClass(HamburgerCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = UIColor(white: 0.95, alpha: 0.95)

        if !atBottom {
            view.frame = CGRectMake(parent.frame.width - width, UIConstants.ToolbarHeight, width, height)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        (view.window as! BraveMainWindow).windowTouchFilter = nil
    }

    override func viewDidAppear(animated: Bool) {
        (view.window as! BraveMainWindow).windowTouchFilter = self
    }

    func share() {
    }

    func buttonClicked(sender: UIButton) {
        postAsyncToMain(0.1) {
           sender.tintColor = UIColor.blackColor()
        }
        postAsyncToMain(0.15) {
            self.close()
        }
        postAsyncToMain(0.1) {
            switch sender.tag {
            case ButtonAction.share.rawValue:
                if let tab = getApp().tabManager.selectedTab, url = tab.displayURL {
                    getApp().browserViewController.presentActivityViewController(url, tab: tab, sourceView: self.parent, sourceRect: self.parent.frame, arrowDirection: .Up)
                }

            case ButtonAction.settings.rawValue:
                if getApp().profile == nil {
                    return
                }

                let settingsTableViewController = BraveSettingsView(style: .Grouped)
                settingsTableViewController.profile = getApp().profile
                let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
                controller.modalPresentationStyle = UIModalPresentationStyle.FormSheet
                getApp().browserViewController.presentViewController(controller, animated: true, completion: nil)

            case ButtonAction.desktopSite.rawValue:
                if let tab = getApp().tabManager.selectedTab, url = tab.displayURL {
                    (getApp().browserViewController as! BraveBrowserViewController).newTabForDesktopSite(url: url)
                }

            case ButtonAction.find.rawValue:
                getApp().browserViewController.updateFindInPageVisibility(visible: true)

            default:
                print("")
            }
        }
    }
    
    func buttonUp(sender: UIButton) {
        postAsyncToMain(0.1) {
           sender.tintColor = UIColor.blackColor()
        }
    }

    func buttonDown(sender: UIButton) {
        sender.tintColor = blueColor
    }
}

extension HamburgerMenu : WindowTouchFilter {
    func filterTouch(touch: UITouch) -> Bool {
        if let touchview = touch.view where !touchview.isDescendantOfView(view) && touchview != parentButton {
            self.close()
        }

        return false
    }
}


extension HamburgerMenu : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left  + flowLayout.sectionInset.right + (flowLayout.minimumInteritemSpacing * CGFloat(itemsPerRow - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(itemsPerRow))
        return CGSize(width: size, height: Int(55))
    }
}

extension HamburgerMenu : UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! HamburgerCell

        c.label.text = titles[indexPath.item]
        c.button.setImage(UIImage(named: images[indexPath.item])?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        c.tintColor = UIColor.blackColor()

        c.button.addTarget(self, action: #selector(buttonDown), forControlEvents: .TouchDown)
        c.button.addTarget(self, action: #selector(buttonUp), forControlEvents: [.TouchCancel, .TouchDragExit, .TouchUpOutside])
        c.button.addTarget(self, action: #selector(buttonClicked), forControlEvents: .TouchUpInside)

        c.button.tag = indexPath.item
        if indexPath.item != ButtonAction.settings.rawValue {
            c.button.enabled = isWebPage
        }
        return c
    }
}

class HamburgerCell : UICollectionViewCell {
    var button: UIButton = UIButton()
    var label: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(button)
        contentView.addSubview(label)

        button.snp_makeConstraints { make in
            make.top.equalTo(contentView)
            make.centerX.equalTo(contentView)
            make.width.height.equalTo(30)
        }
        button.backgroundColor = UIColor.clearColor()
        button.opaque = false

        label.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(contentView)
            make.height.equalTo(25)
        }

        label.numberOfLines = 0
        label.font = UIFont.systemFontOfSize(10)
        label.lineBreakMode = .ByWordWrapping
        label.textAlignment = .Center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
