/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import SQLite

private let _singleton = HttpsEverywhere()

class HttpsEverywhere {
    static let kNotificationDataLoaded = "kNotificationDataLoaded"
    static let prefKey = "braveHttpsEverywhere"
    static let prefKeyDefaultValue = true
    static let dataVersion = "5.2"
    var isNSPrefEnabled = true
    var db: Connection?
    let fifoCacheOfRedirects = FifoDict()
    let fifoCacheOfDomainToIds = FifoDict()

    lazy var networkFileLoader: NetworkDataFileLoader = {
        let targetsDataUrl = NSURL(string: "https://s3.amazonaws.com/https-everywhere-data/\(dataVersion)/httpse.sqlite")!
        let dataFile = "httpse-\(dataVersion).sqlite"
        let loader = NetworkDataFileLoader(url: targetsDataUrl, file: dataFile, localDirName: "https-everywhere-data")
        loader.delegate = self

        self.runtimeDebugOnlyTestVerifyResourcesLoaded()

        return loader
    }()

    class var singleton: HttpsEverywhere {
        return _singleton
    }

    private init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HttpsEverywhere.prefsChanged(_:)), name: NSUserDefaultsDidChangeNotification, object: nil)
        updateEnabledState()
    }

    func loadSqlDb() {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard let path = networkFileLoader.pathToExistingDataOnDisk() else { return }
        do {
            db = try Connection(path, readonly: true)
            // try db!.execute("CREATE INDEX IF NOT EXISTS hostidx ON targets(host)") -> useful for testing, db will have this already
            try db!.execute("PRAGMA synchronous=OFF")
            NSLog("»»»»»» https-e db loaded")
            NSNotificationCenter.defaultCenter().postNotificationName(HttpsEverywhere.kNotificationDataLoaded, object: self)
        }  catch {
            print("\(error)")
        }
    }

    func updateEnabledState() {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        isNSPrefEnabled = BraveApp.getPrefs()?.boolForKey(HttpsEverywhere.prefKey) ?? true
    }

    @objc func prefsChanged(info: NSNotification) {
        updateEnabledState()
    }

    private func applyRedirectRuleForIds(ids: [Int], url: NSURL) -> NSURL? {
        guard let db = db else { return nil }

        let contents = Expression<String>("contents")
        let id = Expression<Int>("id")

        func urlWithTrailingSlash(url: NSURL) -> String {
            let s = url.absoluteString
            if !s.endsWith("/") && !String(url.path).isEmpty {
                return s + "/"
            }
            return s
        }

        // HTTPSE ruleset expects trailing slash in certain cases, however NSURL makes no guarantee about 'canonicalizing' URLs to a particular form. We could either modify the regex slightly or just check against an input URL with a trailing slash
        // Using latter method as matter of preference
        let urlWithSlash = urlWithTrailingSlash(url)
        let urlCandidates = urlWithSlash != url.absoluteString ?
            [url.absoluteString, urlWithSlash] : [url.absoluteString]

        let whereClause = "id = '" + ids.map({ "\($0)" }).joinWithSeparator("' OR id = '") + "'"
        for row in db.prepare("SELECT contents FROM rulesets WHERE \(whereClause)") {
            guard let r = row[0] as? String, data = r.utf8EncodedData else { continue }
            do {
                guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary,
                    ruleset = json["ruleset"] as? NSDictionary,
                    rules = ruleset["rule"] as? NSArray else {
                        return nil
                }

                if let props = ruleset["$"] as? [String:AnyObject] {
                    if props.indexForKey("default_off") != nil {
                        return nil
                    }
                    if props.indexForKey("platform") != nil {
                        return nil
                    }
                }

                if let exclusion = ruleset["exclusion"] as? [NSDictionary] {
                    for rule in exclusion {
                        guard let props = rule["$"] as? NSDictionary, pattern = props["pattern"] as? String else { return nil }
                        let regex = try NSRegularExpression(pattern: pattern, options: [])
                        for item in urlCandidates {
                            let result = regex.firstMatchInString(item, options: [], range: NSMakeRange(0, item.characters.count))
                            if let result = result where result.range.location != NSNotFound {
                                return nil
                            }
                        }
                    }
                }

                for rule in rules {
                    guard let props = rule["$"] as? NSDictionary, from = props["from"] as? String, to = props["to"] as? String else { return nil }
                    let regex = try NSRegularExpression(pattern: from, options: [])

                    for item in urlCandidates {
                        let newUrl = regex.stringByReplacingMatchesInString(item, options: [], range: NSMakeRange(0, item.characters.count), withTemplate: to)

                        if !newUrl.startsWith(url.absoluteString) {
                            return NSURL(string: newUrl)
                        }
                    }
                }
            } catch {
                print("Failed to load targetsLoader: \(error)")
            }
        }
        return nil
    }

    private func mapExactDomainToIdForLookup(domains: [String]) -> [Int]? {
        guard let db = db else { return nil }
        var result = [Int]()

        for domain in domains {
            if let cached = fifoCacheOfDomainToIds.getItem(domain) as? [Int] {
                return cached // any one of the domains matches, we are good to go
            }
        }

        let whereClause = "host = '" + domains.joinWithSeparator("' OR host = '") + "'"
        let r = db.prepare("select ids, host from targets where \(whereClause) limit 1").generate()
        if let row = r.next() { // only use one result, doesn't matter which one
            guard let d = row[0] as? String else { return result }
            let data = d.substringWithRange(d.startIndex.advancedBy(1)..<d.endIndex.advancedBy(-1))
            let parts = data.characters.split(",")
            var cache = [Int]()
            for part in parts {
                if let j = Int(String(part)) {
                    cache.append(j)
                    result.append(j)
                }
            }
            fifoCacheOfDomainToIds.addItem(row[1] as? String ?? "", value: cache)
        }
        return result
    }

    private func mapDomainToIdForLookup(domain: String) -> [Int] {
        let parts = (domain as NSString).componentsSeparatedByString(".")
        if parts.count < 1 {
            return [Int]()
        }
        var s = [String]()
        for i in 0..<(parts.count - 1) {
            let slice = parts[i..<parts.count].joinWithSeparator(".")
            let prefix = (i > 0) ? "*." : ""
            s.append(prefix + slice)
        }
        if s.count == 0 {
            return [Int]()
        }
        if s.count == 1 {
            s.append("*." + s[0])
        }
        return mapExactDomainToIdForLookup(s) ?? [Int]()
    }

    func tryRedirectingUrl(url: NSURL) -> NSURL? {
        if url.scheme.startsWith("https") {
            return nil
        }

        if let redirect = fifoCacheOfRedirects.getItem(url.absoluteString) {
            if redirect === NSNull() {
                return nil
            } else {
                return redirect as? NSURL
            }
        }

        // This internal function is so we can store the result in the fifoCacheOfRedirects
        func redirect(url: NSURL) -> NSURL? {
            guard let url = NSURL(string: stripLocalhostWebServer(url.absoluteString)), host = url.host else {
                return nil
            }

            let ids = mapDomainToIdForLookup(host)
            if ids.count < 1 {
                return nil
            }

            guard let newUrl = applyRedirectRuleForIds(ids, url: url) else { return nil }

            let ignoredlist = [
                "m.slashdot.org" // see https://github.com/brave/browser-ios/issues/104
            ]
            for item in ignoredlist {
                if url.absoluteString.contains(item) || (newUrl.host?.contains(item) ?? false) {
                    return nil
                }
            }

            return newUrl
        }

        let redirected = redirect(url)
        fifoCacheOfRedirects.addItem(url.absoluteString, value: redirected)
        return redirected
    }
}

extension HttpsEverywhere: NetworkDataFileLoaderDelegate {
    func fileLoader(loader: NetworkDataFileLoader, setDataFile data: NSData?) {
        if data != nil {
            loadSqlDb()
        }
    }

    func fileLoaderHasDataFile(_: NetworkDataFileLoader) -> Bool {
        return db != nil
    }
}


// Build in test cases, swift compiler is mangling the test cases in HttpsEverywhereTests.swift and they are failing. The compiler is falsely casting  AnyObjects to XCUIElement, which then breaks the runtime tests, I don't have time to look at this further ATM.
extension HttpsEverywhere {
    private func runtimeDebugOnlyTestDomainsRedirected() {
        #if DEBUG
            let urls = ["thestar.com", "thestar.com/", "www.thestar.com", "apple.com", "xkcd.com"]
            for url in urls {
                guard let _ =  HttpsEverywhere.singleton.tryRedirectingUrl(NSURL(string: "http://" + url)!) else {
                    BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E validation failed on url: \(url)")
                    return
                }
            }

            let url = HttpsEverywhere.singleton.tryRedirectingUrl(NSURL(string: "http://www.googleadservices.com/pagead/aclk?sa=L&ai=CD0d/")!)
            if url == nil || !url!.absoluteString.hasSuffix("?sa=L&ai=CD0d/") {
                BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E validation failed for url args")
            }
        #endif
    }

    private func runtimeDebugOnlyTestVerifyResourcesLoaded() {
        #if DEBUG
            postAsyncToMain(10) {
                if self.db == nil {
                    BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E didn't load")
                } else {
                    self.runtimeDebugOnlyTestDomainsRedirected()
                }
            }
        #endif
    }
}
