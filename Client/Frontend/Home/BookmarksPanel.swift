/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger
import Eureka


// Brave extension
extension MergedSQLiteBookmarks {
    public func editBookmarkFolder(bookmark:BookmarkFolder, title:String, completion:dispatch_block_t)  {
        self.buffer.editBookmarkFolder(bookmark, title:title, completion:completion)
    }

    public func editBookmarkItem(bookmark:BookmarkItem, title:String, parentGUID: String, completion:dispatch_block_t)  {
        self.buffer.editBookmarkItem(bookmark, title:title, parentGUID:parentGUID, completion:completion)
    }

    public func reorderBookmarks(folderGUID:String, bookmarksOrder:[String], completion:dispatch_block_t)  {
        self.buffer.reorderBookmarks(folderGUID, bookmarksOrder:bookmarksOrder, completion:completion)
    }

    public func createFolder(folderName:String, completion:dispatch_block_t)  {
        self.buffer.createFolder(folderName, completion:completion)
    }
}


private let log = Logger.browserLogger

let BookmarkStatusChangedNotification = "BookmarkStatusChangedNotification"

// MARK: - Placeholder strings for Bug 1232810.

let deleteWarningTitle = NSLocalizedString("This folder isn't empty.", tableName: "BookmarkPanelDeleteConfirm", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
let deleteWarningDescription = NSLocalizedString("Are you sure you want to delete it and its contents?", tableName: "BookmarkPanelDeleteConfirm", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
let deleteCancelButtonLabel = NSLocalizedString("Cancel", tableName: "BookmarkPanelDeleteConfirm", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.")
let deleteDeleteButtonLabel = NSLocalizedString("Delete", tableName: "BookmarkPanelDeleteConfirm", comment: "Button label for the button that deletes a folder and all of its children.")

// Placeholder strings for Bug 1248034
let emptyBookmarksText = NSLocalizedString("Bookmarks you save will show up here.", comment: "Status label for the empty Bookmarks state.")

// MARK: - UX constants.

struct BookmarksPanelUX {
    private static let BookmarkFolderHeaderViewChevronInset: CGFloat = 10
    private static let BookmarkFolderChevronSize: CGFloat = 20
    private static let BookmarkFolderChevronLineWidth: CGFloat = 4.0
    private static let BookmarkFolderTextColor = UIColor(red: 92/255, green: 92/255, blue: 92/255, alpha: 1.0)
    private static let WelcomeScreenPadding: CGFloat = 15
    private static let WelcomeScreenItemTextColor = UIColor.grayColor()
    private static let WelcomeScreenItemWidth = 170
    private static let SeparatorRowHeight: CGFloat = 0.5
}

public extension UIBarButtonItem {
    
    public class func createImageButtonItem(image:UIImage, action:Selector) -> UIBarButtonItem {
        let button = UIButton(type: .Custom)
        button.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        button.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        button.setImage(image, forState: .Normal)
        
        return UIBarButtonItem(customView: button)
    }
    
    public class func createFixedSpaceItem(width:CGFloat) -> UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        item.width = width
        return item
    }
}

class BkPopoverControllerDelegate : NSObject, UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None;
    }
}

class BorderedButton: UIButton {
    let buttonBorderColor = UIColor.lightGrayColor()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.borderColor = buttonBorderColor.CGColor
        layer.borderWidth = 0.5
        
        contentEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
    override var highlighted: Bool {
        didSet {
            let fadedColor = buttonBorderColor.colorWithAlphaComponent(0.2).CGColor
            
            if highlighted {
                layer.borderColor = fadedColor
            } else {
                layer.borderColor = buttonBorderColor.CGColor
                
                let animation = CABasicAnimation(keyPath: "borderColor")
                animation.fromValue = fadedColor
                animation.toValue = buttonBorderColor.CGColor
                animation.duration = 0.4
                layer.addAnimation(animation, forKey: "")
            }
        }
    }
}


class BookmarkEditingViewController: FormViewController {
    var completionBlock:((controller:BookmarkEditingViewController) -> Void)?
    var sourceTable:UITableView!
    
    var folders:[BookmarkFolder]!
    
    var bookmarksPanel:BookmarksPanel!
    var bookmark:BookmarkNode!
    var currentFolderGUID:String!
    var bookmarkIndexPath:NSIndexPath!
    
    let BOOKMARK_TITLE_ROW_TAG:String = "BOOKMARK_TITLE_ROW_TAG"
    let BOOKMARK_URL_ROW_TAG:String = "BOOKMARK_URL_ROW_TAG"
    let BOOKMARK_FOLDER_ROW_TAG:String = "BOOKMARK_FOLDER_ROW_TAG"

    var originalTitle:String!
    var originalFolderGUID:String!

    var titleRow:TextRow!
    var urlRow:LabelRow!
    var folderSelectionRow:PickerInlineRow<BookmarkFolder>!
    
    init(sourceTable table:UITableView!, indexPath:NSIndexPath, currentFolderGUID:String, bookmarksPanel:BookmarksPanel, bookmark:BookmarkNode!, folders:[BookmarkFolder]) {
        super.init(nibName: nil, bundle: nil)
        sourceTable = table
        
        self.folders = folders
        self.bookmark = bookmark
        self.bookmarksPanel = bookmarksPanel
        self.bookmarkIndexPath = indexPath
        self.currentFolderGUID = currentFolderGUID
        
        self.originalTitle = self.bookmark.title
        self.originalFolderGUID = currentFolderGUID
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        //called when we're about to be popped, so use this for callback
        if let block = self.completionBlock {
            block(controller: self)
        }
    }
    
    var isEditingFolder:Bool {
        return bookmark is BookmarkFolder
    }
    
    var isEditingBookmarkItem:Bool {
        return !isEditingFolder
    }

    //may be the same as the original
    var newFolderGUID:String! {
        return folderSelectionRow?.value?.guid
    }
    
    //may be the same as the original
    var newTitle:String! {
        guard let possibleNewTitle = titleRow.value else {
            return originalTitle
        }
        
        let newTitle:String! = possibleNewTitle.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if newTitle.characters.count == 0 {
            return originalTitle
        }
        return newTitle
    }

    var bookmarkTitleChanged:Bool {
        return self.newTitle != self.originalTitle
    }

    var bookmarkFolderChanged:Bool {
        return self.newFolderGUID != self.originalFolderGUID
    }

    var bookmarkDataChanged:Bool {
        if isEditingFolder {
            return bookmarkTitleChanged
        }
        
        return bookmarkTitleChanged || bookmarkFolderChanged
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let firstSectionName = isEditingBookmarkItem ?  NSLocalizedString("Bookmark Info", comment: "Bookmark Info Section Title") : NSLocalizedString("Bookmark Folder", comment: "Bookmark Folder Section Title")
        
        let nameSection = Section(firstSectionName)
            
        nameSection <<< TextRow() { row in
                row.tag = BOOKMARK_TITLE_ROW_TAG
                row.title = NSLocalizedString("Name", comment: "Bookmark name/title")
                row.value = bookmark.title
                self.titleRow = row
            }
        
        form +++ nameSection
        
        if isEditingBookmarkItem {

            nameSection <<< LabelRow() { row in
                row.tag = BOOKMARK_URL_ROW_TAG
                row.title = NSLocalizedString("URL", comment: "Bookmark URL")
                row.value = (bookmark as! BookmarkItem).url
                self.urlRow = row
            }
            
        
            form +++ Section(NSLocalizedString("Location", comment: "Bookmark folder location"))
            <<< PickerInlineRow<BookmarkFolder>() { (row : PickerInlineRow<BookmarkFolder>) -> Void in
                row.tag = BOOKMARK_FOLDER_ROW_TAG
                row.title = NSLocalizedString("Folder", comment: "Folder")
                row.displayValueFor = { (rowValue: BookmarkFolder?) in
                    return (rowValue?.title) ?? ""
                }

                // This is a hack to workaround https://github.com/brave/browser-ios/issues/450
                // TODO: we should be able to just do foldersArray = self.folders, not sure why multiple MemoryBookmarkFolder called 'Root Folder' appear
                var foundOneRootFolder = false
                let foldersArray = self.folders.filter({ (folder) -> Bool in
                    if let _ = folder as? MemoryBookmarkFolder {
                        if foundOneRootFolder {
                            return false
                        }
                        foundOneRootFolder = true
                    }
                    return true
                })
                row.options = foldersArray
                
                var currentFolder:BookmarkFolder!
                for i in 0..<foldersArray.count {
                    let folder = foldersArray[i]
                    if self.currentFolderGUID == folder.guid {
                        currentFolder = folder
                        break
                    }
                }
                row.value = currentFolder
                self.folderSelectionRow = row
            }
        }
        
    }
}

class BookmarksPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var source: BookmarksModel?
    var parentFolders = [BookmarkFolder]()
    var bookmarkFolder: BookmarkFolder? {
        didSet {
            if let folder = bookmarkFolder {
                self.title = folder.title
            }
        }
    }
    var folderList:[BookmarkFolder] = [BookmarkFolder]()
    
    var currentItemCount:Int {
        return source?.current.count ?? 0
    }
    var orderedBookmarkGUIDs:[String] = [String]()
    var orderUpdatedBookmarkGUIDs:[String] = [String]()

    private let BookmarkFolderCellIdentifier = "BookmarkFolderIdentifier"
    private let BookmarkSeparatorCellIdentifier = "BookmarkSeparatorIdentifier"
    private let BookmarkFolderHeaderViewIdentifier = "BookmarkFolderHeaderIdentifier"

    var editBookmarksToolbar:UIToolbar!

    var editBookmarksButton:UIBarButtonItem!
    var addRemoveFolderButton:UIBarButtonItem!
    var removeFolderButton:UIBarButtonItem!
    var addFolderButton:UIBarButtonItem!
    
    var isEditingInvidivualBookmark:Bool = false

    init() {
        super.init(nibName: nil, bundle: nil)
        self.title = NSLocalizedString("Bookmarks", comment: "title for bookmarks panel")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BookmarksPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)

        self.tableView.registerClass(SeparatorTableCell.self, forCellReuseIdentifier: BookmarkSeparatorCellIdentifier)
        self.tableView.registerClass(BookmarkFolderTableViewCell.self, forCellReuseIdentifier: BookmarkFolderCellIdentifier)
        self.tableView.registerClass(BookmarkFolderTableViewHeader.self, forHeaderFooterViewReuseIdentifier: BookmarkFolderHeaderViewIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        print("BookmarksPanel: viewdidappear")
        reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
        let width = self.view.bounds.size.width
        let toolbarHeight = CGFloat(44)
        editBookmarksToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: width, height: toolbarHeight))
        createEditBookmarksToolbar()
        editBookmarksToolbar.barTintColor = UIColor(white: 225/255.0, alpha: 1.0)
        
        self.view.addSubview(editBookmarksToolbar)
        
        editBookmarksToolbar.snp_makeConstraints { make in
            make.height.equalTo(toolbarHeight)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
            return
        }
        
        tableView.snp_makeConstraints { make in
            make.bottom.equalTo(self.view).inset(UIEdgeInsetsMake(0, 0, toolbarHeight, 0))
            return
        }
        
        // If we've not already set a source for this panel, fetch a new model from
        // the root; otherwise, just use the existing source to select a folder.
        guard let source = self.source else {
            // Get all the bookmarks split by folders
            if let bookmarkFolder = bookmarkFolder {
                profile.bookmarks.modelFactory >>== { $0.modelForFolder(bookmarkFolder).upon(self.onModelFetched) }
            } else {
                profile.bookmarks.modelFactory >>== { $0.modelForRoot().upon(self.onModelFetched) }
            }
            return
        }

        if let bookmarkFolder = bookmarkFolder {
            source.selectFolder(bookmarkFolder).upon(onModelFetched)
        } else {
            source.selectFolder(BookmarkRoots.MobileFolderGUID).upon(onModelFetched)
        }
    }
    
    func disableTableEditingMode() {
        dispatch_async(dispatch_get_main_queue()) {
            self.switchTableEditingMode(true)
        }
    }
    
    var bookmarksOrderChanged:Bool {
        return orderedBookmarkGUIDs != orderUpdatedBookmarkGUIDs
    }
    
    func switchTableEditingMode(forceOff:Bool = false) {
        // TODO: why async??
        dispatch_async(dispatch_get_main_queue()) {
            let editMode:Bool = forceOff ? false : !self.tableView.editing
            self.tableView.setEditing(editMode, animated: forceOff ? false : true)
            //only when the 'edit' button has been pressed
            self.updateAddRemoveFolderButton(editMode)
            self.updateEditBookmarksButton(editMode)
        }
    }
    
    func updateEditBookmarksButton(tableIsEditing:Bool) {
        self.editBookmarksButton.title = tableIsEditing ? NSLocalizedString("Done", comment: "Done") : NSLocalizedString("Edit", comment: "Edit")
        self.editBookmarksButton.style = tableIsEditing ? .Done : .Plain

    }
    
    /*
     * Subfolders can only be added to the root folder, and only subfolders can be deleted/removed, so we use
     * this button (on the left side of the bookmarks toolbar) for both functions depending on where we are.
     * Therefore when we enter edit mode on the root we show 'new folder'
     * the button disappears when not in edit mode in both cases. When a subfolder is not empty,
     * pressing the remove folder button will show an error message explaining why (suboptimal, but allows to expose this functionality)
     */
    func updateAddRemoveFolderButton(tableIsEditing:Bool) {
        
        if !tableIsEditing {
            addRemoveFolderButton.enabled = false
            addRemoveFolderButton.title = nil
            return
        }

        addRemoveFolderButton.enabled = true

        var targetButton:UIBarButtonItem!
        
        if bookmarkFolder == nil { //on root, this button allows adding subfolders
            targetButton = addFolderButton
        } else { //on a subfolder, this button allows removing the current folder (if empty)
            targetButton = removeFolderButton
        }
        
        addRemoveFolderButton.title = targetButton.title
        addRemoveFolderButton.style = targetButton.style
        addRemoveFolderButton.target = targetButton.target
        addRemoveFolderButton.action = targetButton.action
    }
    
    func createEditBookmarksToolbar() {
        var items = [UIBarButtonItem]()
        
        items.append(UIBarButtonItem.createFixedSpaceItem(5))

        //these two buttons are created as placeholders for the data/actions in each case. see #updateAddRemoveFolderButton and
        //#switchTableEditingMode
        addFolderButton = UIBarButtonItem(title: NSLocalizedString("New Folder", comment: "New Folder"),
                                          style: .Plain, target: self, action: #selector(onAddBookmarksFolderButton))
        removeFolderButton = UIBarButtonItem(title: NSLocalizedString("Delete Folder", comment: "Delete Folder"),
                                             style: .Plain, target: self, action: #selector(onDeleteBookmarksFolderButton))
        
        //this is the button that actually lives in the toolbar
        addRemoveFolderButton = UIBarButtonItem()
        items.append(addRemoveFolderButton)

        updateAddRemoveFolderButton(false)
        
        items.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil))

        editBookmarksButton = UIBarButtonItem(title: NSLocalizedString("Edit", comment: "Edit"),
                                              style: .Plain, target: self, action: #selector(onEditBookmarksButton))
        items.append(editBookmarksButton)
        items.append(UIBarButtonItem.createFixedSpaceItem(5))
        
        
        editBookmarksToolbar.items = items
    }
    
    func onDeleteBookmarksFolderButton() {
        guard let currentFolder = self.bookmarkFolder else {
            NSLog("Delete folder button pressed but no folder object exists (probably at root), ignoring.")
            return
        }
        let itemCount = source?.current.count ?? 0
        let folderGUID = currentFolder.guid
        let canDeleteFolder = (itemCount == 0)
        let title = canDeleteFolder ? "Delete Folder" : "Oops!"
        let message = canDeleteFolder ? "Deleting folder \"\(currentFolder.title)\". This action can't be undone. Are you sure?" : "You can't delete a folder that contains items. Please delete all items and try again."
        let okButtonTitle = canDeleteFolder ? "Delete" : "OK"
        let okButtonType = canDeleteFolder ? UIAlertActionStyle.Destructive : UIAlertActionStyle.Default
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: okButtonType,
            handler: { (alertA: UIAlertAction!) in
                if canDeleteFolder {
                    
                    self.profile.bookmarks.modelFactory >>== {
                        $0.removeByGUID(folderGUID).uponQueue(dispatch_get_main_queue()) { res in
                            if res.isSuccess {
                                self.navigationController?.popViewControllerAnimated(true)
                                self.currentBookmarksPanel().reloadData()
                            }
                        }
                    }
                }
        }))
        if canDeleteFolder {
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel,
                handler: nil))
        }
        self.presentViewController(alert, animated: true) {
        }
    }
    
    func onAddBookmarksFolderButton() {
        
        let alert = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: UIAlertControllerStyle.Alert)

        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (alertA: UIAlertAction!) in
            self.addFolder(alertA, alertController:alert)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)

        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "<folder name>"
            textField.secureTextEntry = false
        })
        
        self.presentViewController(alert, animated: true) {}
    }

    func addFolder(alert: UIAlertAction!, alertController: UIAlertController) {
        postAsyncToBackground {
            if let folderName = alertController.textFields?[0].text  {
                if let sqllitbk = self.profile.bookmarks as? MergedSQLiteBookmarks {
                    sqllitbk.createFolder(folderName) {
                        postAsyncToMain {
                            self.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func onEditBookmarksButton() {
        switchTableEditingMode()
    }

    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let item = orderUpdatedBookmarkGUIDs.removeAtIndex(sourceIndexPath.item)
        orderUpdatedBookmarkGUIDs.insert(item, atIndex: destinationIndexPath.item)

        //check if the table has been reordered, if so make the changes persistent
        if self.tableView.editing && bookmarksOrderChanged {
            orderedBookmarkGUIDs = orderUpdatedBookmarkGUIDs
            postAsyncToBackground {
                if let sqllitbk = self.profile.bookmarks as? MergedSQLiteBookmarks {
                    let folderGUID = self.bookmarkFolder?.guid ?? BookmarkRoots.MobileFolderGUID

                    sqllitbk.reorderBookmarks(folderGUID, bookmarksOrder: self.orderedBookmarkGUIDs) {
                        postAsyncToMain {
                            self.reloadData()
                        }
                    }
                }
            }

        }
    }

    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged:
            self.reloadData()
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    private func onModelFetched(result: Maybe<BookmarksModel>) {
        guard let model = result.successValue else {
            self.onModelFailure(result.failureValue)
            return
        }
        self.onNewModel(model)
    }

    private func hasRowAtIndexPath(tableView: UITableView, indexPath: NSIndexPath) -> Bool {
        return indexPath.section < tableView.numberOfSections && indexPath.row < tableView.numberOfRowsInSection(indexPath.section)
    }

    private func onNewModel(model: BookmarksModel) {
        postAsyncToMain {
            let count = self.currentItemCount
            self.source = model
            let newCount = self.currentItemCount
            
            if self.bookmarkFolder == nil { //we're on root, load folders into picker
                self.folderList = [BookmarkFolder]()
            }
            self.orderedBookmarkGUIDs.removeAll()
            
            let rootFolder = MemoryBookmarkFolder(guid: BookmarkRoots.MobileFolderGUID, title: "Root Folder", children: [])
            self.folderList.append(rootFolder)
            for i in 0..<newCount {
                if let item = model.current[i] {
                    self.orderedBookmarkGUIDs.append(item.guid)
                    if let f = item as? BookmarkFolder {
                        self.folderList.append(f)
                    }
                }
            }
            self.orderUpdatedBookmarkGUIDs = self.orderedBookmarkGUIDs
            
            self.tableView.reloadData()
            if count != newCount && newCount > 0 {
                let newIndexPath = NSIndexPath(forRow: newCount-1, inSection: 0)
                if self.hasRowAtIndexPath(self.currentBookmarksPanel().tableView, indexPath: newIndexPath) {
                    self.currentBookmarksPanel().tableView.scrollToRowAtIndexPath(newIndexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                } else {
                    print("😡 This is a nasty bug, it should be fixed.")
                }
            }
        }
    }

    private func onModelFailure(e: Any) {
        editBookmarksButton.enabled = false
        log.error("Error: failed to get data: \(e)")
    }
    
    func currentBookmarksPanel() -> BookmarksPanel {
        guard let controllers = navigationController?.viewControllers.filter({ $0 as? BookmarksPanel != nil }) else {
            return self
        }
        return controllers.last as? BookmarksPanel ?? self
    }
    
    override func reloadData() {
        print("reload data")
        //profile = getApp().profile

        if let source = self.source {
            source.reloadData().upon(self.onModelFetched)
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source?.current.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let source = source, bookmark = source.current[indexPath.row] else {
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }

        func makeCell(image image: UIImage? = nil, icon: Favicon? = nil, longPressForContextMenu: Bool = false) -> UITableViewCell {
            let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)

            if self.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath) {
                cell.separatorInset = UIEdgeInsetsZero
            }

            if longPressForContextMenu {
                cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
                let lp = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnCell))
                cell.addGestureRecognizer(lp)
            }

            func restrictImageSize() {
                if cell.imageView?.image == nil {
                    return
                }
                let itemSize = CGSizeMake(25, 25);
                UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.mainScreen().scale);
                let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                cell.imageView?.image!.drawInRect(imageRect)
                cell.imageView?.image! = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }

            func setIcon(icon: Favicon?, withPlaceholder placeholder: UIImage) {
                if let icon = icon {
                    let imageURL = NSURL(string: icon.url)
                    cell.imageView?.sd_setImageWithURL(imageURL, placeholderImage: placeholder, completed: {
                        image, error, cache, url in
                        restrictImageSize()
                    })
                    return
                }
                cell.imageView?.image = placeholder
            }

            if let icon = icon {
                setIcon(icon, withPlaceholder: FaviconFetcher.defaultFavicon)
            } else if let image = image {
                cell.imageView?.image = image
                restrictImageSize()
            }

            return cell
        }

        switch (bookmark) {
        case let item as BookmarkItem:
            let cell: UITableViewCell!
            if let url = bookmark.favicon?.url.asURL where url.scheme == "asset" {
                cell = makeCell(image: UIImage(named: url.host!), longPressForContextMenu: true)
            } else {
                cell = makeCell(icon: bookmark.favicon, longPressForContextMenu: true)
            }

            cell.textLabel?.font = UIFont.systemFontOfSize(14)
            if item.title.isEmpty {
                cell.textLabel?.text = item.url
            } else {
                cell.textLabel?.text = item.title
            }

            cell.accessoryType = .None
            return cell
        case is BookmarkSeparator:
            return tableView.dequeueReusableCellWithIdentifier(BookmarkSeparatorCellIdentifier, forIndexPath: indexPath)
        case let bookmark as BookmarkFolder:
            let cell = makeCell(image: UIImage(named: "bookmarks_folder_hollow"))
            cell.textLabel?.font = UIFont.boldSystemFontOfSize(14)
            cell.textLabel?.text = bookmark.title
            cell.accessoryType = .DisclosureIndicator
            return cell
        default:
            // This should never happen.
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? BookmarkFolderTableViewCell {
            cell.textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        }
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let it = self.source?.current[indexPath.row] where it is BookmarkSeparator {
            return BookmarksPanelUX.SeparatorRowHeight
        }

        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Show a full-width border for cells above separators, so they don't have a weird step.
        // Separators themselves already have a full-width border, but let's force the issue
        // just in case.
        let this = self.source?.current[indexPath.row]
        if (indexPath.row + 1) < self.source?.current.count {
            let below = self.source?.current[indexPath.row + 1]
            if this is BookmarkSeparator || below is BookmarkSeparator {
                return true
            }
        }
        return super.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return indexPath
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        guard let source = source else {
            return
        }

        let bookmark = source.current[indexPath.row]

        switch (bookmark) {
        case let item as BookmarkItem:
            if tableView.editing {
                //show editing view for bookmark item
                self.showEditBookmarkController(tableView, indexPath: indexPath)
            }
            else {
                if let url = NSURL(string: item.url) {
                    homePanelDelegate?.homePanel(self, didSelectURL: url, visitType: VisitType.Bookmark)
                }
            }
            break

        case let folder as BookmarkFolder:
            if tableView.editing {
                //show editing view for bookmark item
                self.showEditBookmarkController(tableView, indexPath: indexPath)
            }
            else {
                print("Selected \(folder.guid)")
                let nextController = BookmarksPanel()
                nextController.parentFolders = parentFolders + [source.current]
                nextController.bookmarkFolder = folder
                nextController.folderList = self.folderList
                nextController.homePanelDelegate = self.homePanelDelegate
                nextController.profile = self.profile
                source.modelFactory.uponQueue(dispatch_get_main_queue()) { maybe in
                    guard let factory = maybe.successValue else {
                        // Nothing we can do.
                        return
                    }
                    nextController.source = BookmarksModel(modelFactory: factory, root: folder)
                    //on subfolders, the folderpicker is the same as the root
                    let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self.navigationController, action: nil)
                    self.navigationItem.leftBarButtonItem = backButton
                    self.navigationController?.pushViewController(nextController, animated: true)
                }
            }
            break

        default:
            // You can't do anything with separators.
            break
        }
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        guard let source = source else {
            return .None
        }

        if source.current[indexPath.row] is BookmarkSeparator {
            // Because the deletion block is too big.
            return .None
        }

        if source.current.itemIsEditableAtIndex(indexPath.row) ?? false {
            return .Delete
        }

        return .None
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        guard let source = self.source else {
            return [AnyObject]()
        }

        let deleteTitle = NSLocalizedString("Delete", tableName: "BookmarksPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.")
        let editTitle = NSLocalizedString("Edit", tableName: "BookmarksPanel", comment: "Action button for editing bookmarks in the bookmarks panel.")

        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: deleteTitle, handler: { (action, indexPath) in
            guard let bookmark = source.current[indexPath.row] else {
                return
            }

            assert(!(bookmark is BookmarkFolder))
            //folder deletion is dealt with within a folder.
            if bookmark is BookmarkFolder {
                // TODO: check whether the folder is empty (excluding separators). If it isn't
                // then we must ask the user to confirm. Bug 1232810.
                log.debug("Not deleting folder.")
                return
            }

            log.debug("Removing rows \(indexPath).")

            // Block to do this -- this is UI code.
            guard let factory = source.modelFactory.value.successValue else {
                log.error("Couldn't get model factory. This is unexpected.")
                self.onModelFailure(DatabaseError(description: "Unable to get factory."))
                return
            }

            if let err = factory.removeByGUID(bookmark.guid).value.failureValue {
                log.debug("Failed to remove \(bookmark.guid).")
                self.onModelFailure(err)
                return
            }

            guard let reloaded = source.reloadData().value.successValue else {
                log.debug("Failed to reload model.")
                return
            }

            self.tableView.beginUpdates()
            self.source = reloaded
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
            self.tableView.endUpdates()

            NSNotificationCenter.defaultCenter().postNotificationName(BookmarkStatusChangedNotification, object: bookmark, userInfo:["added": false])
        })
        
        
        let edit = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: editTitle, handler: { (action, indexPath) in
            guard let bookmark = source.current[indexPath.row] else {
                return
            }
            
            if bookmark is BookmarkFolder {
                return
            }
            
            self.showEditBookmarkController(tableView, indexPath: indexPath)
        })

        return [delete, edit]
    }
    
    func showEditBookmarkController(tableView: UITableView, indexPath:NSIndexPath) {
        guard let source = source else {
            return
        }

        guard let bookmark = source.current[indexPath.row] else {
            return
        }

        let currentFolderGUID = self.bookmarkFolder?.guid ?? BookmarkRoots.MobileFolderGUID

        let nextController = BookmarkEditingViewController(sourceTable:self.tableView,indexPath: indexPath, currentFolderGUID:currentFolderGUID, bookmarksPanel: self, bookmark: bookmark, folders: self.folderList)

        nextController.completionBlock = {(controller: BookmarkEditingViewController) -> Void in
            self.isEditingInvidivualBookmark = false
            if controller.bookmarkDataChanged {
                postAsyncToBackground {
                    self.updateBookmarkData(bookmark, newTitle: controller.newTitle, newFolderGUID: controller.newFolderGUID, atIndexPath: controller.bookmarkIndexPath)
                    NSNotificationCenter.defaultCenter().postNotificationName(BookmarkStatusChangedNotification, object: bookmark, userInfo:["added": false])
                }
            }
        }
        self.isEditingInvidivualBookmark = true
        self.navigationController?.pushViewController(nextController, animated: true)
    }

    func updateBookmarkData(bookmark:BookmarkNode, newTitle:String, newFolderGUID: String?, atIndexPath indexPath: NSIndexPath) {
        postAsyncToBackground {
            
            let refreshBlock:dispatch_block_t = { postAsyncToMain { self.reloadData() }}
            
            if let sqllitbk = self.profile.bookmarks as? MergedSQLiteBookmarks {
                //we split up the update into class-specific functions so we get more compile time & runtime checks before writing into the DB
                if let bookmarkItem = bookmark as? BookmarkItem, guid = newFolderGUID {
                    //bookmark items ALWAYS pass along the folderGUID even if not changed hence we can force newFolderGUID!
                    sqllitbk.editBookmarkItem(bookmarkItem, title:newTitle, parentGUID: guid, completion: refreshBlock)
                    
                }
                else if let bookmarkFolder = bookmark as? BookmarkFolder {
                    sqllitbk.editBookmarkFolder(bookmarkFolder, title:newTitle, completion: refreshBlock)
                }
            }
        }
    }
}

private protocol BookmarkFolderTableViewHeaderDelegate {
    func didSelectHeader()
}

extension BookmarksPanel: BookmarkFolderTableViewHeaderDelegate {
    private func didSelectHeader() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

class BookmarkFolderTableViewCell: TwoLineTableViewCell {
    private let ImageMargin: CGFloat = 12

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.backgroundColor = UIColor.clearColor()
        textLabel?.tintColor = BookmarksPanelUX.BookmarkFolderTextColor

        imageView?.image = UIImage(named: "bookmarkFolder")

        self.editingAccessoryType = .DisclosureIndicator

        separatorInset = UIEdgeInsetsZero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class BookmarkFolderTableViewHeader : UITableViewHeaderFooterView {
    var delegate: BookmarkFolderTableViewHeaderDelegate?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIConstants.HighlightBlue
        return label
    }()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .Left)
        chevron.tintColor = UIConstants.HighlightBlue
        chevron.lineWidth = BookmarksPanelUX.BookmarkFolderChevronLineWidth
        return chevron
    }()

    lazy var topBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    lazy var bottomBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        userInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BookmarkFolderTableViewHeader.viewWasTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizer)

        addSubview(topBorder)
        addSubview(bottomBorder)
        contentView.addSubview(chevron)
        contentView.addSubview(titleLabel)

        chevron.snp_makeConstraints { make in
            make.left.equalTo(contentView).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
            make.size.equalTo(BookmarksPanelUX.BookmarkFolderChevronSize)
        }

        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(chevron.snp_right).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.right.greaterThanOrEqualTo(contentView).offset(-BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
        }

        topBorder.snp_makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func viewWasTapped(gestureRecognizer: UITapGestureRecognizer) {
        delegate?.didSelectHeader()
    }
}
