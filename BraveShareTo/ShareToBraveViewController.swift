
import UIKit
import Social
import MobileCoreServices

class ShareToBraveViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        return
    }

    override func configurationItems() -> [AnyObject]! {
        let item: NSExtensionItem = extensionContext!.inputItems[0] as! NSExtensionItem
        let itemProvider: NSItemProvider = item.attachments![0] as! NSItemProvider
        var url: NSString = ""
        let type = kUTTypeURL as String
        if itemProvider.hasItemConformingToTypeIdentifier(type) {
            itemProvider.loadItemForTypeIdentifier(type, options: nil, completionHandler: {
                (urlItem, error) in
                url = (urlItem as! NSURL).absoluteString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
                UIApplication.sharedApplication().openURL(NSURL(string: "brave://open-url?url=\(url)")!)
                dispatch_after(
                    dispatch_time(
                        DISPATCH_TIME_NOW,
                        Int64(0.1 * Double(NSEC_PER_SEC))
                    ),
                    dispatch_get_main_queue(), { self.cancel() })

            })
        }

        return []
    }


    override func viewDidAppear(animated: Bool) {
        // Stop keyboard from showing
        textView.resignFirstResponder()
        textView.editable = false

        super.viewDidAppear(animated)
    }

    override func willMoveToParentViewController(parent: UIViewController?) {
        view.alpha = 0
    }
}
