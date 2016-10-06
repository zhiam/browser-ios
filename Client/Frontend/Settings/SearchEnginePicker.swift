/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

protocol SearchEnginePickerDelegate {
    func searchEnginePicker(searchEnginePicker: SearchEnginePicker, didSelectSearchEngine engine: OpenSearchEngine?) -> Void
}

class SearchEnginePicker: UITableViewController {
    var delegate: SearchEnginePickerDelegate?
    var engines: [OpenSearchEngine]!
    var selectedSearchEngineName: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = Strings.DefaultSearchEngine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.Cancel, style: .Plain, target: self, action: #selector(SearchEnginePicker.SELcancel))
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engines.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let engine = engines[indexPath.item]
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.textLabel?.text = engine.shortName
        cell.imageView?.image = engine.image?.createScaled(CGSize(width: OpenSearchEngine.PreferredIconSize, height: OpenSearchEngine.PreferredIconSize))
        if engine.shortName == selectedSearchEngineName {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let engine = engines[indexPath.item]
        delegate?.searchEnginePicker(self, didSelectSearchEngine: engine)

        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else { return }
        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        telemetry(action: "search engine changed", props: ["engine" : cell.textLabel?.text ?? ""])
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
    }

    func SELcancel() {
        delegate?.searchEnginePicker(self, didSelectSearchEngine: nil)
    }
}
