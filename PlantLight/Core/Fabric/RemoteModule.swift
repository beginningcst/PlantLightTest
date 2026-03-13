
import Foundation
import UIKit

public enum MonitorComponentModel: String {
    case base = "BASE"
    case metrics = "METRICS"
    case purchase = "PURCHASE"
    case netprocessingState = "NETWORKING"
    case adAttribute = "ASA"
    case exception = "EXCEPTION"
}

enum ResizeQuickExecutor: String {
    case error
    case warning
    case info
}


// MARK: - Log
struct RemoteModule {
    
    public static func log(module: MonitorComponentModel, level: ResizeQuickExecutor = .info, content: String) {
#if DEBUG
        let prefix: String
        switch level {
        case .info:
            prefix = "🟢"
        case .warning:
            prefix = "🟡"
        case .error:
            prefix = "🔴"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        if module != .base {
            print("[\(timestamp)] \(prefix)[\(module.rawValue)]=>\(content)")
        }else {
            print("[\(timestamp)] \(prefix)\(content)")
        }
#endif
    }
    
    public static func SendContextValidator(name: String, level: ResizeQuickExecutor = .info,  parameters: [String: Any] = [:]) {
        log(module: .purchase, level: level, content: "Event: \(name), parameters: \(parameters)")
    }
}
