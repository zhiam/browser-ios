/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import SQLite
import Shared

private let _singleton = HttpsEverywhere()
private let levelDbFileName = "httpse.leveldb"

class HttpsEverywhere {
    static let kNotificationDataLoaded = "kNotificationDataLoaded"
    static let prefKey = "braveHttpsEverywhere"
    static let prefKeyDefaultValue = true
    static let dataVersion = "5.2"
    var isNSPrefEnabled = true

    var httpseDb = HttpsEverywhereObjC()

    lazy var networkFileLoader: NetworkDataFileLoader = {
        let targetsDataUrl = NSURL(string: "https://s3.amazonaws.com/https-everywhere-data/\(dataVersion)/httpse.leveldb.tgz")!
        let dataFile = "httpse-\(dataVersion).leveldb.tgz"
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


    func loadDb(dir dir:String, name:String) {
        let path = dir + "/" + name
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            return
        }

        httpseDb.load(path)
        if !httpseDb.isLoaded() {
            do { try NSFileManager.defaultManager().removeItemAtPath(path) }
            catch {}
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName(HttpsEverywhere.kNotificationDataLoaded, object: self)
            print("httpse loaded")
        }
        assert(httpseDb.isLoaded())
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


    func tryRedirectingUrl(url: NSURL) -> NSURL? {
        if url.scheme.startsWith("https") {
            return nil
        }

        let result = httpseDb.tryRedirectingUrl(url)
        if result.isEmpty {
            return nil
        } else {
            return NSURL(string: result)
        }
    }
}

private func unzipFile(dir dir: String, data: NSData) {
    let unzip = data.gunzippedData()
    let fm = NSFileManager.defaultManager()

    do {
        try fm.createFilesAndDirectoriesAtPath(dir,
                                               withTarData: unzip,
                                               progress:  { _ in
        })
    }
    catch {
        #if DEBUG
            BraveApp.showErrorAlert(title: " error", error: "\(error)")
        #endif
    }
}


extension HttpsEverywhere: NetworkDataFileLoaderDelegate {
    func unzipAndLoad(dir dir: String, data: NSData) {
        httpseDb.close()
        succeed().upon() { _ in

            let fm = NSFileManager.defaultManager()
            if fm.fileExistsAtPath(dir + "/" + levelDbFileName) {
                do { try NSFileManager.defaultManager().removeItemAtPath(dir + "/" + levelDbFileName) }
                catch { NSLog("failed to remove leveldb file before unzip \(error)") }
            }

            unzipFile(dir: dir, data: data)
            postAsyncToMain(0) {
                self.loadDb(dir: dir, name: levelDbFileName)
            }
        }
    }
    func fileLoader(loader: NetworkDataFileLoader, setDataFile data: NSData?) {
        guard let data = data else { return }
        let (dir, _) = loader.createAndGetDataDirPath()
        unzipAndLoad(dir: dir, data: data)
    }

    func fileLoaderHasDataFile(loader: NetworkDataFileLoader) -> Bool {
        if !httpseDb.isLoaded() {
            let (dir, _) = loader.createAndGetDataDirPath()
            self.loadDb(dir: dir, name: levelDbFileName)
        }
        print("httpse doesn't need to d/l: \(httpseDb.isLoaded())")
        return httpseDb.isLoaded()
    }

    func fileLoaderDelegateWillHandleInitialRead(loader: NetworkDataFileLoader) -> Bool {
        return true
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
                if !self.httpseDb.isLoaded() {
                    BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E didn't load")
                } else {
                    self.runtimeDebugOnlyTestDomainsRedirected()
                }
            }
        #endif
    }
}
