import SQLite

private let _singleton = HttpsEverywhere()

class HttpsEverywhere {
    static let kNotificationDataLoaded = "kNotificationDataLoaded"
    static let prefKeyHttpsEverywhereOn = "braveHttpsEverywhere"
    static let dataVersion = "5.1.2"
    var isEnabled = true
    var db: Connection?
    var domainToIdMapping: NSDictionary?

    lazy var rulesetsLoader: NetworkDataFileLoader = {
        let rulesetsDataUrl = NSURL(string: "https://s3.amazonaws.com/https-everywhere-data/\(dataVersion)/rulesets.sqlite")!
        let dataFile = "https-ruleset-\(dataVersion).sqlite"
        let loader = NetworkDataFileLoader(url: rulesetsDataUrl, file: dataFile, localDirName: "https-everywhere-data-rulesets")
        loader.delegate = self
        return loader
    }()

    lazy var targetsLoader: NetworkDataFileLoader = {
        let targetsDataUrl = NSURL(string: "https://s3.amazonaws.com/https-everywhere-data/\(dataVersion)/httpse-targets.json")!
        let dataFile = "https-targets-\(dataVersion).json_fastcoded"
        let loader = NetworkDataFileLoader(url: targetsDataUrl, file: dataFile, localDirName: "https-everywhere-data-targets")
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
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let obj = BraveApp.getPref(HttpsEverywhere.prefKeyHttpsEverywhereOn)
        isEnabled = obj as? Bool ?? true
    }

    @objc func prefsChanged(info: NSNotification) {
        updateEnabledState()
    }

    func loadSqlDb() {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard let path = rulesetsLoader.pathToExistingDataOnDisk() else { return }
        do {
            db = try Connection(path)
        }  catch {
            print("\(error)")
        }
    }

    func loadData() {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

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
        if let val = domainToIdMapping[domain] as? [Int] {
            return val[0]
        }
        return nil
    }

    private func mapDomainToIdForLookup(domain: String) -> [Int] {
        var resultIds = [Int]()
        let parts = domain.characters.split(".")
        if parts.count < 1 {
            return resultIds
        }
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
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if !isEnabled || url.scheme.startsWith("https") {
            return nil
        }

        var str = stripLocalhostWebServer(url.absoluteString)
        if str.hasSuffix("/") {
            str = String(str.characters.dropLast())
        }
        guard let url = NSURL(string: str), host = url.host else {
            return nil
        }


        let scheme = url.scheme

        let ids = mapDomainToIdForLookup(host)
        if ids.count < 1 {
            return nil
        }

        guard let newHost = applyRedirectRuleForIds(ids, schemeAndHost: scheme + "://" + host) else { return nil }

        var newUrl = NSURL(string: newHost)
        if let path = url.path {
            newUrl = newUrl?.URLByAppendingPathComponent(path)
        }
        if let query = url.query, url = newUrl?.absoluteString {
            newUrl = NSURL(string: url + "?" + query)
        }

        let ignoredlist = [
            "m.slashdot.org" // see https://github.com/brave/browser-ios/issues/104
        ]
        for item in ignoredlist {
            if url.absoluteString.contains(item) || newHost.contains(item) {
                return nil
            }
        }

        return newUrl
    }
}

extension HttpsEverywhere: NetworkDataFileLoaderDelegate {
    // Build in test cases, swift compiler is mangling the test cases in HttpsEverywhereTests.swift and they are failing. The compiler is falsely casting  AnyObjects to XCUIElement, which then breaks the runtime tests, I don't have time to look at this further ATM.
    private func runtimeDebugOnlyTestDomainsRedirected() {
#if DEBUG
        if HttpsEverywhere.singleton.isEnabled {
            let urls = ["thestar.com", "thestar.com/", "www.thestar.com", "apple.com", "xkcd.com"]
            for url in urls {
                guard let _ =  HttpsEverywhere.singleton.tryRedirectingUrl(NSURL(string: "http://" + url)!) else {
                    BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E validation failed on url: \(url)")
                    return
                }
            }

            let url = HttpsEverywhere.singleton.tryRedirectingUrl(NSURL(string: "http://www.googleadservices.com/pagead/aclk?sa=L&ai=CD0d")!)
            if url == nil || !url!.absoluteString.hasSuffix("?sa=L&ai=CD0d") {
                BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E validation failed for url args")
            }
        }
#endif
    }

    private func runtimeDebugOnlyTestVerifyResourcesLoaded() {
#if DEBUG
        delay(60) {
            if self.domainToIdMapping == nil && self.db == nil {
                BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E didn't load")
            }
        }
#endif
    }

    private func runtimeDebugOnlyTestFastCoder(json: NSDictionary, fastCodedData: NSData) {
#if DEBUG
        // delay a bit to let loading complete
        delay(2) { dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            let obj = FastCoder.objectWithData(fastCodedData) as? NSDictionary
            assert(obj != nil, "Fastcoder validation failed, obj nil")
            assert(NSDictionary(dictionary: obj!).isEqualToDictionary(json as [NSObject : AnyObject]), "Fastcoder validation failed, obj mismatch")
        }}
#endif
    }

    private func checkBothLoadsAreComplete() {
        delay(0) { // post to main thread
            self.runtimeDebugOnlyTestVerifyResourcesLoaded()

            if self.domainToIdMapping != nil && self.db != nil {
                NSNotificationCenter.defaultCenter().postNotificationName(HttpsEverywhere.kNotificationDataLoaded, object: self)
                self.runtimeDebugOnlyTestDomainsRedirected()
            }
        }
    }

    private func finishedUnarchivingPreparsedJson(json: NSDictionary) {
        delay(0) { // post to main thread
            self.domainToIdMapping = json
            self.checkBothLoadsAreComplete()
        }
    }

    func fileLoader(loader: NetworkDataFileLoader, convertDataBeforeWriting data: NSData, etag: String?) {
        if loader !== targetsLoader {
            loader.finishWritingToDisk(data, etag: etag)
            return
        }

        do {
            let start = NSDate()

            guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary else { return }
            let fastCodedData = FastCoder.dataWithRootObject(json)

            NSLog("»»»»» HTTPS-E convert to archive time: \(NSDate().timeIntervalSinceDate(start))")

            loader.finishWritingToDisk(fastCodedData, etag: etag)

            runtimeDebugOnlyTestFastCoder(json, fastCodedData: fastCodedData)
        } catch {
            print("Failed to load targetsLoader: \(error) \(NSString(data: data, encoding: NSUTF8StringEncoding)))")
        }
    }

    func fileLoader(loader: NetworkDataFileLoader, setDataFile data: NSData?) {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard let data = data else { return }

        if loader === targetsLoader {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
                let start = NSDate()

                guard let obj = FastCoder.objectWithData(data) as? NSDictionary else { return }
                self.finishedUnarchivingPreparsedJson(obj)

                NSLog("»»»»» HTTPS-E unarchive time: \(NSDate().timeIntervalSinceDate(start))")
            }
        } else if loader === rulesetsLoader {
            loadSqlDb()
            checkBothLoadsAreComplete()
        }
    }

    func fileLoaderHasDataFile(_: NetworkDataFileLoader) -> Bool {
        return false
    }
}
