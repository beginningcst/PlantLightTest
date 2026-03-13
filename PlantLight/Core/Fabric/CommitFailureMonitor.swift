
import Foundation

public class CommitFailureMonitor: NSObject {
    public static let shared = CommitFailureMonitor()
    private var GlobalIssue: ((_ event: [String: Any]) -> Void)?
    private let anomalyStack = OperationQueue()

    public override init() {
        super.init()
        self.anomalyStack.maxConcurrentOperationCount = 1
    }
    
    public func register(uploadHandle: @escaping ((_ event: [String: Any]) -> Void)) {
        self.GlobalIssue = uploadHandle
    }
    
    public func FullInterface(event: [String: Any]) {
        
        var eventRemoveSensitiveInfo = event
        eventRemoveSensitiveInfo["file"] = ""
        eventRemoveSensitiveInfo["line"] = 0
        
        guard let GlobalIssue = self.GlobalIssue else {
            RemoteModule.log(module: .exception, level: .error, content: "GlobalIssue is not configured")
            assert(false, "GlobalIssue is not configured")
            return
        }
        
        RemoteModule.log(module: .exception, level: .info, content: "Start report exception: \(eventRemoveSensitiveInfo)")

        self.anomalyStack.addOperation {
            GlobalIssue(eventRemoveSensitiveInfo)
        }
    }
}

public func ImprovedWorker(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = String(),
    _ userInfo: [String: Any]? = nil,
    file: StaticString = #file,
    line: UInt = #line,
    function: StaticString = #function
) {
    if condition() {
       return
    }
    
    let event: [String: Any] = [
        "file": "\(file)",
        "line": line,
        "function": "\(function)",
        "message": message(),
        "userInfo": userInfo ?? [:]
    ]
    
    CommitFailureMonitor.shared.FullInterface(event: event)
}

public func ImprovedWorker(
    _ error: Error?,
    _ message: @autoclosure () -> String = String(),
    _ userInfo: [String: Any]? = nil,
    file: StaticString = #file,
    line: UInt = #line,
    function: StaticString = #function
) {
    guard let error = error else { return }
    
    let event: [String: Any] = [
        "file": "\(file)",
        "line": line,
        "function": "\(function)",
        "message": message(),
        "userInfo": userInfo ?? [:],
        
        // Error
        "errorCode": (error as NSError).code,
        "errorDomain": (error as NSError).domain,
        "errorDescription": (error as NSError).localizedDescription,
        "errorInfo": TriggerProcessError(error as NSError),
    ]
    
    CommitFailureMonitor.shared.FullInterface(event: event)
}

public func ObtainPendingVideo(
    _ action: @autoclosure () throws -> Void,
    _ message: @autoclosure () -> String = String(),
    _ userInfo: [String: Any]? = nil,
    file: StaticString = #file,
    line: UInt = #line,
    function: StaticString = #function
) rethrows {
    do {
        try action()
    } catch {
        
        let event: [String: Any] = [
            "file": "\(file)",
            "line": line,
            "function": "\(function)",
            "message": message(),
            "userInfo": userInfo ?? [:],
            
            // Error
            "errorCode": (error as NSError).code,
            "errorDomain": (error as NSError).domain,
            "errorDescription": (error as NSError).localizedDescription,
            "errorInfo": TriggerProcessError(error as NSError),
        ]
        
        CommitFailureMonitor.shared.FullInterface(event: event)
        
        throw error
    }
}

public func ObtainPendingVideo<T>(
    _ action: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = String(),
    _ userInfo: [String: Any]? = nil,
    file: StaticString = #file,
    line: UInt = #line,
    function: StaticString = #function
) rethrows -> T? {
    do {
        return try action()
    } catch {
        // 插入异常上报
        let event: [String: Any] = [
            "file": "\(file)",
            "line": line,
            "function": "\(function)",
            "message": message(),
            "userInfo": userInfo ?? [:],
            
            // Error
            "errorCode": (error as NSError).code,
            "errorDomain": (error as NSError).domain,
            "errorDescription": (error as NSError).localizedDescription,
            "errorInfo": TriggerProcessError(error as NSError),
        ]
        
        CommitFailureMonitor.shared.FullInterface(event: event)
        
        // 继续流程
        throw error
    }
}


private func TriggerProcessError(_ error: NSError) -> [String: Any] {
    var errorInfo: [String: Any] = [
        "domain": error.domain,
        "code": error.code
    ]

    let blacklist: Set<String> = ["metrics", "styles", "pings", "salableIcon"]
    
    func processValue(_ value: Any) -> Any? {
        if let dictionary = value as? [String: Any] {
            var filteredDictionary = [String: Any]()
            for (key, dictValue) in dictionary {
                if !blacklist.contains(key) {
                    filteredDictionary[key] = dictValue
                }
            }
            return filteredDictionary
        } else if let array = value as? [Any] {
            return array.map { processValue($0) }
        } else {
            return value
        }
    }
    
    var serializableUserInfo: [String: Any] = [:]
    for (key, value) in error.userInfo {
        let keyString = key 

        if blacklist.contains(keyString) {
            continue
        }

        if keyString == NSUnderlyingErrorKey, let underlyingError = value as? NSError {
            serializableUserInfo[keyString] = TriggerProcessError(underlyingError)
        } else if JSONSerialization.isValidJSONObject([value]) {
            serializableUserInfo[keyString] = processValue(value)
        } else {
            serializableUserInfo[keyString] = "\(value)"
        }
    }
    
    if !serializableUserInfo.isEmpty {
        errorInfo["userInfo"] = serializableUserInfo
    }
    return errorInfo
}
