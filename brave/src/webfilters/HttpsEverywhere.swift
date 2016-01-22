import SQLite

private let _singleton = HttpsEverywhere()

class HttpsEverywhere {
    static let prefKeyHttpsEverywhereOn = "braveHttpsEverywhere"
    static let dataVersion = "5.1.2"
    var isEnabled = true
    var db: Connection?
    var domainToIdMapping: [String: [Int]]?

    lazy var rulesetsLoader: NetworkDataFileLoader = {
        let rulesetsDataUrl = NSURL(string: "https://s3.amazonaws.com/https-everywhere-data/\(dataVersion)/rulesets.sqlite")!
        let dataFile = "https-ruleset-\(dataVersion).sqlite"
        let loader = NetworkDataFileLoader(url: rulesetsDataUrl, file: dataFile, localDirName: "https-everywhere-data")
        loader.delegate = self
        return loader
    }()

    lazy var targetsLoader: NetworkDataFileLoader = {
        let targetsDataUrl = NSURL(string: "https://s3.amazonaws.com/https-everywhere-data/\(dataVersion)/httpse-targets.json")!
        let dataFile = "https-targets-\(dataVersion).json"
        let loader = NetworkDataFileLoader(url: targetsDataUrl, file: dataFile, localDirName: "https-everywhere-data")
        loader.delegate = self
        return loader
    }()

    class var singleton: HttpsEverywhere {
        return _singleton
    }

    private init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "prefsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
        updateEnabledState()
    }

    func updateEnabledState() {
        let obj = BraveApp.getPref(HttpsEverywhere.prefKeyHttpsEverywhereOn)
        isEnabled = obj as? Bool ?? true
    }

    @objc func prefsChanged(info: NSNotification) {
        updateEnabledState()
    }

    func loadSqlDb() {
        guard let path = rulesetsLoader.pathToExistingDataOnDisk() else { return }
        do {
            db = try Connection(path)
        }  catch {
            print("\(error)")
        }
    }

    func loadData() {
        if let _ = rulesetsLoader.pathToExistingDataOnDisk() {
          loadSqlDb()
        } else {
            rulesetsLoader.loadData()
        }
        targetsLoader.loadData()
    }

    private func applyRedirectRuleForIds(ids: [Int], schemeAndHost: String) -> String? {
        guard let db = db else { return nil }
        let table = Table("rulesets")
        let contents = Expression<String>("contents")
        let id = Expression<Int>("id")

        let query = table.select(contents).filter(ids.contains(id))

        for row in db.prepare(query) {
            guard let data = row.get(contents).utf8EncodedData else { continue }
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as AnyObject
                guard let ruleset = json["ruleset"] as? NSDictionary,
                            rules = ruleset["rule"] as? NSArray else {
                    return nil
                }
                if let props = ruleset["$"] {
                    // Sorry: the test target won't compile without these extra (unecessary) casts (possibly http://www.openradar.me/22836823)
                    if let off = props["default_off"] as? AnyObject? , _ = off {
                        return nil
                    }
                    if let platform = props["platform"] as? AnyObject?, _ = platform {
                        return nil
                    }
                }

                if let exclusion = ruleset["exclusion"] as? String {
                    let regex = try NSRegularExpression(pattern: exclusion, options: [])
                    let result = regex.firstMatchInString(schemeAndHost, options: [], range: NSMakeRange(0, schemeAndHost.characters.count))
                    if let result = result where result.range.location != NSNotFound {
                        return nil
                    }
                }

                for rule in rules {
                    guard let props = rule["$"] as? NSDictionary, from = props["from"] as? String, to = props["to"] as? String else { return nil }
                    let regex = try NSRegularExpression(pattern: from, options: [])
                    let url = regex.stringByReplacingMatchesInString(schemeAndHost, options: [], range: NSMakeRange(0, schemeAndHost.characters.count), withTemplate: to)

                    if url != schemeAndHost {
                        return url
                    }
                }
            } catch {
                print("Failed to load targetsLoader: \(error)")
            }

        }
        return nil
    }

    private func mapExactDomainToIdForLookup(domain: String) -> Int? {
        guard let domainToIdMapping = domainToIdMapping else { return nil }
        if let val = domainToIdMapping[domain] {
            return val[0]
        }
        return nil
    }

    private func mapDomainToIdForLookup(domain: String) -> [Int] {
        var resultIds = [Int]()
        let parts = domain.characters.split(".")
        for i in 0..<(parts.count - 1) {
            let slice = Array(parts[i..<parts.count]).joinWithSeparator(".".characters)
            let prefix = (i > 0) ? "*" : ""
            let id = mapExactDomainToIdForLookup(prefix + String(slice))
            if let id = id {
                resultIds.append(id)
            }
        }
        return resultIds
    }

    func tryRedirectingUrl(url: NSURL) -> NSURL? {
        if !isEnabled {
            return nil
        }

        guard let _url = NSURL(string: stripLocalhostWebServer(url.absoluteString)), host = _url.host else {
            return nil
        }

        let scheme = _url.scheme

        let ids = mapDomainToIdForLookup(host)
        if ids.count < 1 {
            return nil
        }
        guard let newHost = applyRedirectRuleForIds(ids, schemeAndHost: scheme + "://" + host + "/") else { return url }
        return NSURL(string: newHost + "/" + (_url.path ?? ""))
    }
}

extension HttpsEverywhere: NetworkDataFileLoaderDelegate {
    func fileLoader(loader: NetworkDataFileLoader, setDataFile data: NSData?) {
        guard let data = data else { return }

        if loader === targetsLoader {
            do {
                guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:[Int]] else { return }
                domainToIdMapping = json
            } catch {
                print("Failed to load targetsLoader: \(error)")
            }
        } else if loader === rulesetsLoader {
            loadSqlDb()
        }
    }

    func fileLoaderHasDataFile(_: NetworkDataFileLoader) -> Bool {
        return false
    }
}

