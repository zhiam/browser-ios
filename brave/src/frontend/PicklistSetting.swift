/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

protocol PicklistSettingOptionsViewDelegate {
    func picklistSetting(setting: PicklistSettingOptionsView, pickedOptionId: Int)
}

class PicklistSettingOptionsView: UITableViewController {
    var options = [(displayName: String, id: Int)]()
    var headerTitle = ""
    var delegate: PicklistSettingOptionsViewDelegate?
    var initialIndex = -1
    var footerMessage = ""

    convenience init(options: [(displayName: String, id: Int)], title: String, current: Int, footerMessage: String) {
        self.init(style: UITableViewStyle.Grouped)
        self.options = options
        self.headerTitle = title
        self.initialIndex = current
        self.footerMessage = footerMessage
    }

    override init(style: UITableViewStyle) {
        super.init(style: style)
    }

    // Here due to 8.x bug: https://openradar.appspot.com/23709930
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.textLabel?.text = options[indexPath.row].displayName
        // cell.tag = options[indexPath.row].uniqueId --> if we want to decouple row order from option order in future
        if initialIndex == indexPath.row {
            cell.accessoryType = .Checkmark
        }
        return cell
    }

    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footerMessage
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerTitle
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count ?? 0
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        navigationController?.popViewControllerAnimated(true)
        delegate?.picklistSetting(self, pickedOptionId: options[indexPath.row].id)
        return nil
    }

    // Don't show delete button on the left.
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }

    // Don't reserve space for the delete button on the left.
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}

//typealias PicklistSettingChoice = (displayName: String, internalObject: AnyObject, optionId: Int)
struct Choice<T> {
    let item: Void -> (displayName: String, object: T, optionId: Int)
}

class PicklistSettingMainItem<T>: Setting, PicklistSettingOptionsViewDelegate {
    let profile: Profile
    let prefName: String
    let displayName: String
    let options: [Choice<T>]
    var picklistFooterMessage = ""
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }
    override var style: UITableViewCellStyle { return .Value1 }
    override var status: NSAttributedString {
        let currentId = getCurrent()
        let option = lookupOptionById(Int(currentId))
        return NSAttributedString(string: option?.item().displayName ?? "", attributes: [ NSFontAttributeName: UIFont.systemFontOfSize(13)])
    }

    func lookupOptionById(id: Int) -> Choice<T>? {
        for option in options {
            if option.item().optionId == id {
                return option
            }
        }
        return nil
    }

    func getCurrent() -> Int {
        return Int(BraveApp.getPrefs()?.intForKey(prefName) ?? 0)
    }

    init(profile: Profile, displayName: String, prefName: String, options: [Choice<T>]) {
        self.profile = profile
        self.displayName = displayName
        self.prefName = prefName
        self.options = options
        super.init(title: NSAttributedString(string: displayName, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    var picklist: PicklistSettingOptionsView? // on iOS8 there is a crash, seems like it requires this to be retained
    override func onClick(navigationController: UINavigationController?) {
        picklist = PicklistSettingOptionsView(options: options.map { ($0.item().displayName,  $0.item().optionId) }, title: displayName, current: getCurrent(), footerMessage: picklistFooterMessage)
        navigationController?.pushViewController(picklist!, animated: true)
        picklist!.delegate = self
    }

    func picklistSetting(setting: PicklistSettingOptionsView, pickedOptionId: Int) {
        profile.prefs.setInt(Int32(pickedOptionId), forKey: prefName)
    }
}

