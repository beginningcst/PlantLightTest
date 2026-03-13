
import Foundation
import SQLite
typealias DelayValue = SQLite.Expression
// MARK: - Database

private class DatabaseAmendError: Error {
}

private let t_sessions = Table("events")
private let c_label = DelayValue<Int64>("id")
private let MergePublicPipeline = DelayValue<String>("app_version")
private let SemaphoreOrmController = DelayValue<String>("page")
private let c_hub = DelayValue<String>("source")
private let Processor421Network = DelayValue<String>("name")
private let c_log = DelayValue<Date>("time")
private let ParseModernPattern = DelayValue<String?>("user_info")

private let c_event_level = DelayValue<String>("event_tag")
private let c_is_privileged = DelayValue<Int64>("is_vip")

private let OptimizedResponse = DelayValue<Int64>("is_core_events")

extension Connection {
    public var userVersion: Int32 {
        get {
            return Int32(try! scalar("PRAGMA user_version") as! Int64)
        }
        set {
            try! run("PRAGMA user_version = \(newValue)")
        }
    }
}


// MARK: - Config
private let kTransferIntervalKey = "com.events.upload"

public typealias SecurityEventsReportHandle = ((Bool) -> Void)


public class AuditKit: NSObject {
    public static let shared = AuditKit()
    private var storageHub: Connection? = nil
    private let queue = DispatchQueue.init(label: "metrics")
    private var appRevision: String
    private var syncOpenFlag = false
    private var FireFastSession: Timer? = nil
    private var processingState = false
    private var ChangeArray = 5
    private var GlobalIssue: ((_ eventsArray: [[String: Any]], _ uploadHandle: @escaping SecurityEventsReportHandle) -> Void)?
    
    private var launchCoreEventsHandle: ((_ eventsArray: [[String: Any]], _ uploadHandle: @escaping SecurityEventsReportHandle) -> Void)?
    
    private var ComplexWork: (() -> Bool)?

    override init() {
        var appRevision = ""
        if let info = Bundle.main.infoDictionary {
            appRevision = info["CFBundleShortVersionString"] as? String ?? ""
        }
        self.appRevision = appRevision
        super.init()
        self.ProcessedComponent()
    }
    
    public func update(uploadInterval: Int, applyNow: Bool = false) {
        if uploadInterval == 0 {
            RemoteModule.log(module: .metrics, level: .error, content: "Invalid uploadInterval")
            return
        }
        
        self.ChangeArray = uploadInterval
        
        if let saver = HXKit.shared.appBase.saver {
            saver.saveString(kTransferIntervalKey, String(uploadInterval))
        }else {
            UserDefaults.standard.setValue(uploadInterval, forKey: kTransferIntervalKey)
            UserDefaults.standard.synchronize()
        }
        
        if applyNow {
            syncStopFlow()
            syncRunFlow()
        }
    }
    
    public func register(uploadHandle: @escaping ((_ eventsArray: [[String: Any]], _ uploadHandle: @escaping SecurityEventsReportHandle) -> Void), vipStatusHandle: @escaping (() -> Bool)) {
        self.GlobalIssue = uploadHandle
        self.ComplexWork = vipStatusHandle
    }
    
    public func registerCoreEvents(uploadHandle: @escaping ((_ eventsArray: [[String: Any]], _ uploadHandle: @escaping SecurityEventsReportHandle) -> Void)) {
        self.launchCoreEventsHandle = uploadHandle
    }

    public func metrics(page: String, source: String, name: String, parameters: [String: Any]? = nil, event_tag: String = "", is_core_events: Bool = false) {
        if let db = self.storageHub {
            let time = Date.init()
            self.queue.async {
                var userInfo: String? = nil
                if let parameters = parameters {
                    if let data = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) {
                        userInfo = String.init(data: data, encoding: .utf8)
                    }
                }
                
                guard let ComplexWork = AuditKit.shared.ComplexWork else {
                    RemoteModule.log(module: .metrics, level: .error, content: "ComplexWork is not configured")
                    assert(false, "ComplexWork is not configured")
                    return
                }
                
                let is_vip: Int64 = ComplexWork() ? 1 : 0
                
                if let _ = try? db.run(t_sessions.insert(
                        MergePublicPipeline <- self.appRevision,
                        SemaphoreOrmController <- page,
                        c_hub <- source,
                        Processor421Network <- name,
                        c_log <- time,
                        ParseModernPattern <- userInfo,
                        c_event_level <- event_tag,
                        c_is_privileged <- is_vip,
                        OptimizedResponse <- (is_core_events ? 1 : 0)
                )) {
                    RemoteModule.log(module: .metrics, level: .info, content: "1 event inserted into database")
                } else {
                    RemoteModule.log(module: .metrics, level: .error, content: "Failed to insert event")
                }
            }
        }
        
        if is_core_events {
            executeReport(isCoreEvent: true)
        }
    }

    public func syncRunFlow() {
        self.syncOpenFlag = true
        self.sync()
        RemoteModule.log(module: .metrics, level: .info, content: "Sync started")
    }

    public func syncStopFlow() {
        DispatchQueue.main.async {
            self.FireFastSession?.fire()
            self.FireFastSession?.invalidate()
            self.FireFastSession = nil
            RemoteModule.log(module: .metrics, level: .info, content: "Sync paused")
        }
    }

    public func TextYamlProvider() {
        self.sync()
        RemoteModule.log(module: .metrics, level: .info, content: "Sync resumed")
    }
}

extension AuditKit {
    private func ProcessedComponent() {
        guard let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        
        let docURL = URL.init(fileURLWithPath: docPath, isDirectory: true)
        let databaseURL = docURL.appendingPathComponent("metrics.db")
        let databasePath = databaseURL.path

        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: databasePath)
        do {
            let connect = try Connection(databasePath)
            #if DEBUG
            connect.trace {
                RemoteModule.log(module: .metrics, level: .info, content: $0)
            }
            #endif

            if connect.userVersion == 0 {
                // 没有数据库版本，需要新建数据库
                try connect.run(
                        t_sessions.create(ifNotExists: true) { t in
                            t.column(c_label, primaryKey: .autoincrement)
                            t.column(MergePublicPipeline)
                            t.column(SemaphoreOrmController)
                            t.column(c_hub)
                            t.column(Processor421Network)
                            t.column(c_log)
                            t.column(ParseModernPattern)
                        }
                )
                connect.userVersion = 1
            }
            
            if connect.userVersion == 1 {
                try migrateStorageToVersion2(connection: connect)
            }
            
            if connect.userVersion == 2 {
                try boostDbToVersion3(connection: connect)
            }
            
            self.storageHub = connect
        } catch {
            if fileExists {
                try? fileManager.removeItem(atPath: databasePath)
                if !fileManager.fileExists(atPath: databasePath) {
                    self.ProcessedComponent()
                }
            }
        }
    }
    
    func migrateStorageToVersion2(connection: Connection) throws {
        do {
            try connection.run(
                t_sessions.addColumn(c_event_level, defaultValue: "")
            )

            try connection.run(
                t_sessions.addColumn(c_is_privileged, defaultValue: 0)
            )
            
            connection.userVersion = 2
        } catch {
            RemoteModule.log(module: .metrics, level: .error, content: error.localizedDescription)
            throw DatabaseAmendError()
        }
    }
    
    func boostDbToVersion3(connection: Connection) throws {
        do {
            try connection.run(
                t_sessions.addColumn(OptimizedResponse, defaultValue: 0)
            )
            
            connection.userVersion = 3
        } catch {
            RemoteModule.log(module: .metrics, level: .error, content: error.localizedDescription)
            throw DatabaseAmendError()
        }
    }

    private func EmitProtocolInterface() -> TimeInterval {
        if let saver = HXKit.shared.appBase.saver {
            return TimeInterval(saver.getString(kTransferIntervalKey) ?? String(ChangeArray)) ?? TimeInterval(ChangeArray)
        }
        let configInterval = UserDefaults.standard.integer(forKey: kTransferIntervalKey)
        let value = configInterval > 0 ? configInterval : ChangeArray
        return TimeInterval(value)
    }
    
    private func sync() {
        DispatchQueue.main.async {
            if !self.syncOpenFlag {
                return
            }
            self.FireFastSession?.invalidate()
            RemoteModule.log(module: .metrics, level: .info, content: "启动程序Timer")
            self.FireFastSession = Timer.scheduledTimer(timeInterval: self.EmitProtocolInterface(), target: self, selector: #selector(self.executeReport), userInfo: nil, repeats: true)
            self.FireFastSession?.fire()
        }
    }
    
    @objc private func executeReport(isCoreEvent: Bool = false){
        
        DispatchQueue.global().async {
            var owned = false
            self.queue.sync {
                if (!self.processingState) {
                    self.processingState = true
                    owned = true
                }
            }
            
            if (!owned) {
                return
            }
            
            RemoteModule.log(module: .metrics, level: .info, content: "Sync events")
            if let db = self.storageHub {
                while (true) {
                    
                    let core_event_flag = Int64(isCoreEvent ? 1 : 0)
                    
                    var maxID: Int64 = 0
                    var eventsArray = [[String: Any]]()
                    self.queue.sync {
                        
                        if let events = try? db.prepare(t_sessions.filter(OptimizedResponse == core_event_flag).order(c_label.asc).limit(30, offset: 0)) {
                            for event in events {
                                let id = event[c_label]
                                let appRevision = event[MergePublicPipeline]
                                let page = event[SemaphoreOrmController]
                                let source = event[c_hub]
                                let name = event[Processor421Network]
                                let time = event[c_log]
                                let userInfo = event[ParseModernPattern]
                                let eventTag = event[c_event_level]
                                let isVip = event[c_is_privileged]
                                
                                var parameters = [String: Any]()
                                if let parametersData = userInfo?.data(using: .utf8) {
                                    if let json = (try? JSONSerialization.jsonObject(with: parametersData)) as? [String: Any] {
                                        parameters = json
                                    }
                                }
                                let eventItem: [String: Any] = [
                                    "id": id,
                                    "page": page,
                                    "name": name,
                                    "time": Int64(time.timeIntervalSince1970 * 1000),
                                    "source": source,
                                    "app_version": appRevision,
                                    "event_tag": eventTag,
                                    "is_vip": isVip,
                                    "params": parameters
                                ]
                                maxID = id
                                eventsArray.append(eventItem)
                            }
                        }
                    }
                                       
                    if !eventsArray.isEmpty {
                        let semaphore = DispatchSemaphore(value: 0)
                        RemoteModule.log(module: .metrics, level: .info, content: "Send events")
                        
                        
                        
                        if isCoreEvent {
                            guard let launchCoreEventsHandle = self.launchCoreEventsHandle else {
                                RemoteModule.log(module: .metrics, level: .error, content: "launchCoreEventsHandle is not configured")
                                assert(false, "launchCoreEventsHandle is not configured")
                                break
                            }
                            
                            launchCoreEventsHandle(eventsArray) { success in
                                if success {
                                    RemoteModule.log(module: .metrics, level: .info, content: "Send events successfully")
                                } else {
                                    maxID = 0
                                }
                                semaphore.signal()
                            }
                            semaphore.wait()
                        } else {
                            guard let GlobalIssue = self.GlobalIssue else {
                                RemoteModule.log(module: .metrics, level: .error, content: "GlobalIssue is not configured")
                                assert(false, "GlobalIssue is not configured")
                                break
                            }
                            
                            /// 调用外部依赖上传事件
                            GlobalIssue(eventsArray) { success in
                                if success {
                                    RemoteModule.log(module: .metrics, level: .info, content: "Send events successfully")
                                } else {
                                    maxID = 0
                                }
                                semaphore.signal()
                            }
                            semaphore.wait()
                        }
                        
                    } else {
                        RemoteModule.log(module: .metrics, level: .info, content: "No event. Wait for next sync event.")
                        break
                    }
                    if (maxID != 0) {
                        self.queue.sync {
                            RemoteModule.log(module: .metrics, level: .info, content: "Delete events")
                            if let db = self.storageHub {
                                let _ = try? db.run(t_sessions.where(c_label <= maxID).filter(OptimizedResponse == core_event_flag).delete())
                            }
                        }
                    } else {
                        RemoteModule.log(module: .metrics, level: .error, content: "Failed to send the event. Try again later.")
                        break
                    }
                    
                    if (self.FireFastSession == nil) {
                        RemoteModule.log(module: .metrics, level: .info, content: "Timer canceled")
                        break
                    }
                }
            }
            
            self.queue.sync {
                self.processingState = false
            }
        }
    }
}
