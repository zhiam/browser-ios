/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

typealias UIAlertActionCallback = (UIAlertAction) -> Void

// MARK: - Extension methods for building specific UIAlertController instances used across the app
extension UIAlertController {

    class func clearPrivateDataAlert(okayCallback: (UIAlertAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: "",
            message: Strings.ThisWillClearAllPrivateDataItCannotBeUndone,
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let noOption = UIAlertAction(
            title: Strings.Cancel,
            style: UIAlertActionStyle.Cancel,
            handler: nil
        )

        let okayOption = UIAlertAction(
            title: Strings.OK,
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

        let areYouSureTitle = Strings.AreYouSure
        let deleteLocalMessage = Strings.LoginsWillBePermanentlyRemoved
        let deleteSyncedDevicesMessage = Strings.LoginsWillBeRemovedFromAllConnectedDevices
        let cancelActionTitle = Strings.Cancel
        let deleteActionTitle = Strings.Delete

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
