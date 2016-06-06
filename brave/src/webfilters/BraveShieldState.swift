import Foundation
import Deferred
import Shared
import Storage

struct BraveShieldTableRow {
    var normalizedDomain = ""
    var shieldState = BraveShieldState.StateEnum.AllOn.rawValue
}

class BraveShieldTable: GenericTable<BraveShieldTableRow> {
    static let tableName = "brave_shield_per_domain"
    static let colDomain = "domain"
    static let colState = "state"

    var db: BrowserDB!
    static func initialize(db: BrowserDB) -> BraveShieldTable? {
        let table = BraveShieldTable()
        table.db = db
        if !db.createOrUpdate(table) {
            return nil
        }
        return table
    }

    override var name: String { return BraveShieldTable.tableName }
    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        " \(BraveShieldTable.colDomain) TEXT NOT NULL UNIQUE, " +
        " \(BraveShieldTable.colState) TINYINT NOT NULL DEFAULT 0 " }

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

    override func getInsertAndArgs(inout item: BraveShieldTableRow) -> (String, [AnyObject?])? {
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
            if let domain = row[BraveShieldTable.colDomain] as? String, state = row[BraveShieldTable.colState] as? Int {
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

            err = conn.executeChange("DELETE FROM \(kSchemaTableName) WHERE name = \(BraveShieldTable.tableName)", withArgs: nil)
            if let err = err {
                print("SQL operation failed: \(err.localizedDescription)")
            }
            
            braveShieldPerNormalizedDomain.removeAll()
            deferred.fill(Maybe(success: ()))
            return err == nil
        }

        return deferred
    }

    public func loadBraveShieldsPerBaseDomain() -> Deferred<()> {
        let deferred = Deferred<()>()
        succeed().upon() { _ in // move off main thread
            if braveShieldForDomainTable == nil {
                braveShieldForDomainTable = BraveShieldTable.initialize(self.db)
            }

            braveShieldForDomainTable?.getRows().upon {
                result in
                if let rows = result.successValue {
                    for item in rows {
                        braveShieldPerNormalizedDomain[item.normalizedDomain] = item.shieldState
                    }
                }
                deferred.fill(())
            }
        }
        return deferred
    }

    public func setBraveShieldForNormalizedDomain(domain: String, state: Int) {
        if state == 0 {
            braveShieldPerNormalizedDomain.removeValueForKey(domain)
        } else {
            braveShieldPerNormalizedDomain[domain] = state
        }

        succeed().upon() { _ in
            if braveShieldForDomainTable == nil {
                braveShieldForDomainTable = BraveShieldTable.initialize(self.db)
            }

            var t = BraveShieldTableRow()
            t.normalizedDomain = domain
            t.shieldState = state
            var err: NSError?
            self.db.transaction(synchronous: true, err: &err) { (connection, inout err:NSError?) -> Bool in
                if state == 0 {
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

var braveShieldPerNormalizedDomain = [String: Int]()

public class BraveShieldState {
    public enum StateEnum: Int  {
        case AllOn = 0
        case AllOff = 1
        case AdblockOff = 2
        case TPOff = 4
        case HTTPSEOff = 8
        case SafeBrowingOff = 16
        case FingerprintProtectionOff = 32
    }

    public init?(state: Int?) {
        if let state = state {
            self.state = state
        } else {
            return nil
        }
    }

    var state = StateEnum.AllOn.rawValue

    func isOnAdBlock() -> Bool {
        return state & StateEnum.AdblockOff.rawValue == 0
    }

    func isOnTrackingProtection() -> Bool {
        return state & StateEnum.TPOff.rawValue == 0
    }

    func isOnHTTPSE() -> Bool {
        return state & StateEnum.HTTPSEOff.rawValue == 0
    }

    func isOnSafeBrowsing() -> Bool {
        return state & StateEnum.SafeBrowingOff.rawValue == 0
    }

    func setState(states:[StateEnum]) {
        state = 0
        for s in states {
            state |= s.rawValue
        }
    }
}