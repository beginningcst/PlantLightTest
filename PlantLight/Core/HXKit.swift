
import UIKit

public typealias HXCryptBlock = ((_ data: Data?) -> Data?)

enum AppStateSetup {
    case zy
    case me
    case production
}

var CurrentEnv: AppStateSetup = {
    let bundle = UIDevice.getBundleID()
    if bundle == HXKit.shared.appBase.bundleID {
        return .production
    }
    if bundle.contains("com.sandbox") {
        return .zy
    }
    return .me
}()

public protocol HXAppBase {
    var enableUIAdapter: Bool { get }
    var bundleID: String { get }
    var iapSharedSecret: String { get }
    
    var apiBaseURL: String { get }
    var apiToken: String { get }
    var apiCommonPath: (getConfig: String, uploadReceipt: String, kAttribute: String, report: String, exception: String, uploadCoreEvents: String, setTk: String) { get }
    
    var designSize: CGSize { get }
    var fontBlock: ((_ pointSize: CGFloat, _ weight: Int?) -> UIFont)? { get }
    
    var saver: HXSaver? { get }
    var cryptVer: String { get }
    var encryptBlock: HXCryptBlock { get }
    var decryptBlock: HXCryptBlock { get }
    
    var parseConfigBlock: ([String: Any]) -> Void { get }
    var serverLocalizationBlock: ((_ key: String) -> String?)? { get }
    var productIds: [String] { get }
    
    var pushWillPresentBlock: (([AnyHashable : Any]) -> Void)? { get }
    var pushDidReceiveBlock: (([AnyHashable : Any]) -> Void)? { get }
    
    var logSendInterval: Int { get }
}

extension HXAppBase {
    var enableUIAdapter: Bool { true }
    var designSize: CGSize { CGSizeMake(414.0, 896.0) }
    var fontBlock: ((_ pointSize: CGFloat, _ weight: Int?) -> UIFont)? { nil }
    var saver: HXSaver? { nil }
    var pushWillPresentBlock: (([AnyHashable : Any]) -> Void)? { nil }
    var pushDidReceiveBlock: (([AnyHashable : Any]) -> Void)? { nil }
    var cryptVer: String { HBFVCryptoVer }
    var encryptBlock: HXCryptBlock {
        {
            data in
            return HBFVEncryptB64(data)
        }
    }
    var decryptBlock: HXCryptBlock {
        {
            data in
            return HBFVDecryptB64(data)
        }
    }
    var logSendInterval: Int { 5 }
}

public class HXKit {
    
    static var shared: HXKit!
    
    var appBase: HXAppBase
    
    var appAccountToken: String = ""
    
    private lazy var kUser: DebugUserSpecialFlag = {
        DebugUserSpecialFlag()
    }()
    
    static var user: DebugUserSpecialFlag {
        shared.kUser
    }
    
    static var iap: ConcurrentBlock {
        ConcurrentBlock.shared
    }
    
    static var log: FacadeScaleMedia.Type {
        FacadeScaleMedia.self
    }
    
    static var isNetworkEnable: Bool {
        return CloudNetProbe.isNetworkEnable
    }
    
    private var PublicOption: CloudNetProbe.ImportBean = .unknown
    
    private init(appBase: HXAppBase) {
        self.appBase = appBase
    }
    
    static func setup(appBase: HXAppBase) {
        if shared == nil {
            shared = HXKit(appBase: appBase)
        }
        guard let shared else { return }
        NotificationCenter.default.addObserver(shared,selector: #selector(SerializeGlobalSchema),
                                               name: Notification.Name(kIAPStateChangeNotify), object: nil)
        if appBase.enableUIAdapter {
            ProxyUIConfigConverter.enable()
        }
        CloudNetProbe.launchWatching()
        ServiceApi.pullPendingAppSettings()
        shared.initMetricsSystem()
        shared.NativeFile()
    }
    
    private func initMetricsSystem() {
        AuditKit.shared.register(
            uploadHandle: { eventsArray, uploadHandle in
                ServiceApi.SignedProtocol(events: eventsArray) { result in
                    // 调用上传处理回调
                    uploadHandle(result.isSuccess)
                }
            },
            vipStatusHandle: {
                // 是否是VIP，根据实际状态返回
                return HXKit.user.isVIP()
            }
        )
        AuditKit.shared.update(
            uploadInterval: appBase.logSendInterval,
            applyNow: true
        )
        CommitFailureMonitor.shared.register(uploadHandle: { info in
            ServiceApi.StorageStack(info)
        })
    }
    
    private func NativeFile() {
//        if !appAccountToken.isEmpty {
//            ConcurrentBlock.shared.JoinProcessor(appAccountToken)
//        }
//        ConcurrentBlock.shared.fetch(productIds:appBase.productIds) { _, _ in
//            
//        }
//        ConcurrentBlock.shared.signupValidateReceiptFromRemote { UnlockedError, validateStatusHandle in
//            ServiceApi.ExportTcp(UnlockedError.base64EncodedString(options: [])
//            ) { success, errorCode, errorMessage in
//                validateStatusHandle(success, errorCode, errorMessage)
//            }
//        }
//        // 上报收据
//        ConcurrentBlock.shared.verifyReceiptFromServer(
//            productId: "",
//            transactionId: ""
//        ) { success, errorCode, errorMessage in
//            // handle completion if needed
//        }
//        ConcurrentBlock.shared.signupCheckReceiptLocal(
//            sharedSecret: appBase.iapSharedSecret
//        ) { locallyVerifyResult in
//            HXKit.user.analyzeVIP(locallyVerifyResult)
//        }
    }
    
    @objc func SerializeGlobalSchema() {
        if PublicOption == .notReachable && CloudNetProbe.isNetworkEnable {
            RemoteModule.log(module: .netprocessingState, content: "Retry request config again.")
            ServiceApi.SaveDetail { _ in
                self.NativeFile()
            }
        }
        PublicOption = CloudNetProbe.networkStatus
    }
    
    func destory() {
        NotificationCenter.default.removeObserver(self)
        CloudNetProbe.ceaseMonitoringAction()
    }
    
    static func registerPush() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.registerPush()
        }
    }
    
    static func font(size: CGFloat, weight: Int? = nil) -> UIFont {
        return ProxyUIConfigConverter.TuneUnlockedSummary(size: size, weight: weight)
    }
}

extension AppDelegate {
    
    static var enteredBgMode: Bool = false
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        if Self.enteredBgMode {
            Self.enteredBgMode = false
            AuditKit.shared.TextYamlProvider()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            KeyAdPropertySet.ProtectedEndpoint { allowTrack in
                
            } completion: { attributionDetails, error in
                if let attributionDetails {
                    ServiceApi.sendAdDetails(attributionDetails)
                }
            }
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        Self.enteredBgMode = true
        AuditKit.shared.syncStopFlow()
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    public func registerPush() {
        let notifiCenter = UNUserNotificationCenter.current()
        notifiCenter.delegate = self
        let types = UNAuthorizationOptions(arrayLiteral: [.alert, .badge, .sound])
        notifiCenter.requestAuthorization(options: types) { (flag, error) in
            if flag {
                RemoteModule.log(module: .base, content: "[PUSH]=>Request register push success")
            } else{
                RemoteModule.log(module: .base, level: .error, content: "[PUSH]=>Request register push fail. Reason: \(error?.localizedDescription ?? "")")
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var token: String = ""
        for i in 0..<deviceToken.count {
            token += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        if !token.isEmpty {
            ServiceApi.VolatileCommit(with: ["push_token": token], completion: nil)
        }
        RemoteModule.log(module: .base, content: "[PUSH]=>Rev Push Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let block = HXKit.shared.appBase.pushDidReceiveBlock {
            block(userInfo)
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void){
        let userInfo = notification.request.content.userInfo
        if let block = HXKit.shared.appBase.pushWillPresentBlock {
            block(userInfo)
        }
        if #available(iOS 14.0, *) {
            completionHandler([.sound, .banner])
        }else {
            completionHandler([.sound, .alert])
        }
    }
}

public protocol HXSaver {
    func saveData(_ key: String, _ value: Data)
    func getData(_ key: String) -> Data?
    func saveString(_ key: String, _ value: String)
    func getString(_ key: String) -> String?
}
