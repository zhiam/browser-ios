import Foundation
import Deferred
import Shared
import Storage

struct BraveShieldTableRow {
    var normalizedDomain = ""
    var shieldState = ""
}

class BraveShieldTable: GenericTable<BraveShieldTableRow> {
    static let tableName = "brave_shield_per_domain"
    static let colDomain = "domain"
    static let colState = "state_json"

    var db: BrowserDB!
    static func initialize(db: BrowserDB) -> BraveShieldTable? {
        let table = BraveShieldTable()
        table.db = db
        if !db.createOrUpdate(table) {
            return nil
        }
        return table
    }

    override var version: Int { return 1 }
    override var name: String { return BraveShieldTable.tableName }
    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        " \(BraveShieldTable.colDomain) TEXT NOT NULL UNIQUE, " +
        " \(BraveShieldTable.colState) TEXT " }

    override func updateTable(db: SQLiteDBConnection, from: Int) -> Bool {
        let to = self.version
        print("Update table \(self.name) from \(from) to \(to)")
        if from == 0 && to >= 1 {
            // changed name/type of state to state_json
            drop(db)
            create(db)
        }
        return false
    }

    func getRows() -> Deferred<Maybe<[BraveShieldTableRow]>> {
        var err: NSError?

        let cursor = db.withReadableConnection(&err) { connection, _ -> Cursor<BraveShieldTableRow> in
            return self.query(connection, options: nil)
        }

        if let err = err {
            cursor.close()
            return deferMaybe(DatabaseError(err: err))
        }

        let items = cursor.asArray()
        cursor.close()
        return deferMaybe(items)
    }

    func makeArgs(item: BraveShieldTableRow) -> [AnyObject?] {
        var args = [AnyObject?]()
        args.append(item.shieldState)
        args.append(item.normalizedDomain)
        return args
    }

    override func getInsertAndArgs( inout item: BraveShieldTableRow) -> (String, [AnyObject?])? {
        return ("INSERT INTO \(BraveShieldTable.tableName) (\(BraveShieldTable.colState), \(BraveShieldTable.colDomain)) VALUES (?,?)", makeArgs(item))
    }

    override func getUpdateAndArgs(inout item: BraveShieldTableRow) -> (String, [AnyObject?])? {
        return ("UPDATE \(BraveShieldTable.tableName) SET \(BraveShieldTable.colState) = ? WHERE \(BraveShieldTable.colDomain) = ?", makeArgs(item))
    }

    override func getDeleteAndArgs(inout item: BraveShieldTableRow?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let item = item {
            args.append(item.normalizedDomain)
            return ("DELETE FROM \(BraveShieldTable.tableName) WHERE \(BraveShieldTable.colDomain) = ?", args)
        }
        return ("DELETE FROM \(BraveShieldTable.tableName)", [])
    }

    override var factory: ((row: SDRow) -> BraveShieldTableRow)? {
        return { row -> BraveShieldTableRow in
            var item = BraveShieldTableRow()
            if let domain = row[BraveShieldTable.colDomain] as? String, state = row[BraveShieldTable.colState] as? String {
                item.normalizedDomain = domain
                item.shieldState = state
            }
            return item
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let filter: AnyObject = options?.filter {
            args.append("%\(filter)%")
            return ("SELECT \(BraveShieldTable.colState), \(BraveShieldTable.colDomain) FROM \(BraveShieldTable.tableName) WHERE \(BraveShieldTable.colDomain) LIKE ?", args)
        }
        return ("SELECT \(BraveShieldTable.colState), \(BraveShieldTable.colDomain) FROM \(BraveShieldTable.tableName)", args)
    }
}


var braveShieldForDomainTable:BraveShieldTable? = nil

extension BrowserProfile {
    public func clearBraveShieldHistory() ->  Success {
        let deferred = Success()

        if braveShieldForDomainTable == nil {
            deferred.fill(Maybe(success: ()))
            return deferred
        }

        var err: NSError? = nil
        db.transaction(&err) { (conn, err) -> Bool in
            err = conn.executeChange("DROP TABLE IF EXISTS \(BraveShieldTable.tableName)", withArgs: nil)
            if let err = err {
                print("SQL operation failed: \(err.localizedDescription)")
            }

            err = conn.executeChange("DELETE FROM \(kSchemaTableName) WHERE name = '\(BraveShieldTable.tableName)'", withArgs: nil)
            if let err = err {
                print("SQL operation failed: \(err.localizedDescription)")
            }
            braveShieldForDomainTable = nil
            BraveShieldState.perNormalizedDomain.removeAll()
            deferred.fill(Maybe(success: ()))
            return err == nil
        }

        return deferred
    }

    public func loadBraveShieldsPerBaseDomain() -> Deferred<Void> {
        let deferred = Deferred<Void>()
        succeed().upon() { _ in // move off main thread
            BraveShieldState.perNormalizedDomain.removeAll()
            braveShieldForDomainTable = BraveShieldTable.initialize(self.db)

            if braveShieldForDomainTable == nil {
                print("🌩 Failed to init BraveShieldTable")
                deferred.fill()
                return
            }

            braveShieldForDomainTable?.getRows().upon {
                result in
                if let rows = result.successValue {
                    for item in rows {
                        let jsonString = item.shieldState
                        let json = JSON(string: jsonString)
                        for (k, v) in json.asDictionary ?? [:] {
                            if let on = v.asBool {
                                BraveShieldState.forDomain(item.normalizedDomain, setState: (k, on))
                            }
                        }
                    }
                }
                deferred.fill(())
            }
        }
        return deferred
    }

    public func setBraveShieldForNormalizedDomain(domain: String, state: (String, Bool?)) {
        BraveShieldState.forDomain(domain, setState: state)

        if PrivateBrowsing.singleton.isOn {
            return
        }

        let persistentState = BraveShieldState.getStateForDomain(domain)

        succeed().upon() { _ in
            if braveShieldForDomainTable == nil {
                braveShieldForDomainTable = BraveShieldTable.initialize(self.db)
            }

            var t = BraveShieldTableRow()
            t.normalizedDomain = domain
            if let state = persistentState, jsonString = state.toJsonString() {
                t.shieldState = jsonString
            }
            var err: NSError?
            self.db.transaction(synchronous: true, err: &err) { (connection, inout err:NSError?) -> Bool in
                if persistentState == nil {
                    braveShieldForDomainTable?.delete(connection, item: t, err: &err)
                    return true
                }

                let id = braveShieldForDomainTable?.insert(connection, item: t, err: &err)
                if id < 0 {
                    braveShieldForDomainTable?.update(connection, item: t, err: &err)
                }
                return true
            }
        }
    }
}

// These override the setting in the prefs
public class BraveShieldState {
    static let kAllOff = "all_off"
    static let kAdBlockAndTp = "adblock_and_tp"
    //static let kTrackingProtection = "tp" // unused
    static let kHTTPSE = "httpse"
    static let kSafeBrowsing = "safebrowsing"
    static let kFPProtection = "fp_protection"
    static let kNoscript = "noscript"

    typealias ShieldKey = String
    typealias DomainKey = String
    static var perNormalizedDomain = [DomainKey: BraveShieldState]()

    static func forDomain(domain: String, setState state:(ShieldKey, Bool?)) {
        var shields = perNormalizedDomain[domain]
        if shields == nil {
            if state.1 == nil {
                return
            }
            shields = BraveShieldState()
        }

        shields!.setState(state.0, on: state.1)
        perNormalizedDomain[domain] = shields!
    }

    static func getStateForDomain(domain: String) -> BraveShieldState? {
        return perNormalizedDomain[domain]
    }

    public init(jsonStateFromDbRow: String) {
        let js = JSON(string: jsonStateFromDbRow)
        for (k,v) in (js.asDictionary ?? [:]) {
            setState(k, on: v.asBool)
        }
    }

    public init() {
    }

    func toJsonString() -> String? {
        return JSON(state).toString()
    }

    func setState(key: ShieldKey, on: Bool?) {
        if let on = on {
            state[key] = on
        } else {
            state.removeValueForKey(key)
        }
    }

    private var state = [ShieldKey:Bool]()

    func isAllOff() -> Bool {
        return state[BraveShieldState.kAllOff] ?? false
    }

    func isNotSet() -> Bool {
        return state.count < 1
    }

    func isOnAdBlockAndTp() -> Bool? {
        return state[BraveShieldState.kAdBlockAndTp] ?? nil
    }

    func isOnHTTPSE() -> Bool? {
        return state[BraveShieldState.kHTTPSE] ?? nil
    }

    func isOnSafeBrowsing() -> Bool? {
        return state[BraveShieldState.kSafeBrowsing] ?? nil
    }

    func isOnScriptBlocking() -> Bool? {
        return state[BraveShieldState.kNoscript] ?? nil
    }

    func isOnFingerprintProtection() -> Bool? {
        return state[BraveShieldState.kFPProtection] ?? nil
    }

    func setStateFromPerPageShield(pageState: BraveShieldState?) {
        setState(BraveShieldState.kNoscript, on: pageState?.isOnScriptBlocking() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyNoScriptOn) ?? false))
        setState(BraveShieldState.kAdBlockAndTp, on: pageState?.isOnAdBlockAndTp() ?? AdBlocker.singleton.isNSPrefEnabled)
        setState(BraveShieldState.kSafeBrowsing, on: pageState?.isOnSafeBrowsing() ?? SafeBrowsing.singleton.isNSPrefEnabled)
        setState(BraveShieldState.kHTTPSE, on: pageState?.isOnHTTPSE() ?? HttpsEverywhere.singleton.isNSPrefEnabled)
        setState(BraveShieldState.kFPProtection, on: pageState?.isOnFingerprintProtection() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyFingerprintProtection) ?? false))
    }
}
