/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

typealias UIAlertActionCallback = (UIAlertAction) -> Void

// MARK: - Extension methods for building specific UIAlertController instances used across the app
extension UIAlertController {

    class func clearPrivateDataAlert(okayCallback: (UIAlertAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: "",
            message: NSLocalizedString("This action will clear all of your private data. It cannot be undone.", tableName: "ClearPrivateDataConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear their private data."),
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let noOption = UIAlertAction(
            title: NSLocalizedString("Cancel", tableName: "ClearPrivateDataConfirm", comment: "The cancel button when confirming clear private data."),
            style: UIAlertActionStyle.Cancel,
            handler: nil
        )

        let okayOption = UIAlertAction(
            title: NSLocalizedString("OK", tableName: "ClearPrivateDataConfirm", comment: "The button that clears private data."),
            style: UIAlertActionStyle.Destructive,
            handler: okayCallback
        )

        alert.addAction(okayOption)
        alert.addAction(noOption)
        return alert
    }

    /**
     Builds the Alert view that asks if the users wants to also delete history stored on their other devices.
     
     - parameter okayCallback: Okay option handler.

     - returns: UIAlertController for asking the user to restore tabs after a crash
     */

    class func clearSyncedHistoryAlert(okayCallback: (UIAlertAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: "",
            message: NSLocalizedString("This action will clear all of your private data, including history from your synced devices.", tableName: "ClearHistoryConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device."),
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let noOption = UIAlertAction(
            title: NSLocalizedString("Cancel", tableName: "ClearHistoryConfirm", comment: "The cancel button when confirming clear history."),
            style: UIAlertActionStyle.Cancel,
            handler: nil
        )

        let okayOption = UIAlertAction(
            title: NSLocalizedString("OK", tableName: "ClearHistoryConfirm", comment: "The confirmation button that clears history even when Sync is connected."),
            style: UIAlertActionStyle.Destructive,
            handler: okayCallback
        )

        alert.addAction(okayOption)
        alert.addAction(noOption)
        return alert
    }

    /**
     Creates an alert view to warn the user that their logins will either be completely deleted in the 
     case of local-only logins or deleted across synced devices in synced account logins.

     - parameter deleteCallback: Block to run when delete is tapped.
     - parameter hasSyncedLogins: Boolean indicating the user has logins that have been synced.

     - returns: UIAlertController instance
     */
    class func deleteLoginAlertWithDeleteCallback(
        deleteCallback: UIAlertActionCallback,
        hasSyncedLogins: Bool) -> UIAlertController {

        let areYouSureTitle = NSLocalizedString("Are you sure?",
            tableName: "LoginManager",
            comment: "Prompt title when deleting logins")
        let deleteLocalMessage = NSLocalizedString("Logins will be permanently removed.",
            tableName: "LoginManager",
            comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them")
        let deleteSyncedDevicesMessage = NSLocalizedString("Logins will be removed from all connected devices.",
            tableName: "LoginManager",
            comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices")
        let cancelActionTitle = NSLocalizedString("Cancel",
            tableName: "LoginManager",
            comment: "Prompt option for cancelling out of deletion")
        let deleteActionTitle = NSLocalizedString("Delete",
            tableName: "LoginManager",
            comment: "Button in login detail screen that deletes the current login")

        let deleteAlert: UIAlertController
        if hasSyncedLogins {
            deleteAlert = UIAlertController(title: areYouSureTitle, message: deleteSyncedDevicesMessage, preferredStyle: .Alert)
        } else {
            deleteAlert = UIAlertController(title: areYouSureTitle, message: deleteLocalMessage, preferredStyle: .Alert)
        }

        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        let deleteAction = UIAlertAction(title: deleteActionTitle, style: .Destructive, handler: deleteCallback)

        deleteAlert.addAction(cancelAction)
        deleteAlert.addAction(deleteAction)

        return deleteAlert
    }
}
