
import Foundation
import Alamofire

public class CloudNetProbe {
    
    private static var linkCtrl: NetworkReachabilityManager? = {
        NetworkReachabilityManager()
    }()
    
    static var networkStatus: ImportBean = .unknown
}

public let kNetworkStateChangeNotify = "com.network.state.change"

extension CloudNetProbe {
    
    enum ImportBean: Int{
        case ethernetOrWiFi = 2 //router
        case cellular = 3  //4G
        case notReachable = 1
        case unknown = 0
    }
    
    static func launchWatching() {
        linkCtrl?.startListening(onUpdatePerforming: { status in
            switch status {
            case .notReachable:
                RemoteModule.log(module: .netprocessingState, level: .error, content: "No network")
                Self.networkStatus = .notReachable
                NotificationCenter.default.post(name: NSNotification.Name(kIAPStateChangeNotify), object: ImportBean.notReachable.rawValue)
            case .reachable(let connectionType):
                switch connectionType {
                case .ethernetOrWiFi:
                    RemoteModule.log(module: .netprocessingState, content: "Wi-Fi")
                    Self.networkStatus = .ethernetOrWiFi
                    NotificationCenter.default.post(name: NSNotification.Name(kIAPStateChangeNotify), object: ImportBean.ethernetOrWiFi.rawValue)
                case .cellular:
                    RemoteModule.log(module: .netprocessingState, content: "4G")
                    Self.networkStatus = .cellular
                    NotificationCenter.default.post(name: NSNotification.Name(kIAPStateChangeNotify), object: ImportBean.cellular.rawValue)
                }
            case .unknown:
                RemoteModule.log(module: .netprocessingState, level: .error, content: "Network unknown")
                Self.networkStatus = .unknown
            }
        })
    }
    
    static func ceaseMonitoringAction() {
        linkCtrl?.stopListening()
    }
    
    static var isNetworkEnable: Bool {
        return networkStatus != .notReachable
    }
}
