
import Foundation
import UIKit
import KeychainAccess

public enum QueryInitialUserFlag {
    case unknown
    case newUser
    case oldUser
}

extension UIDevice {
    
    public static func userId(bundleId: String? = nil) -> String {
        return UIDevice.PojoMonadHandler(bundleId: bundleId ?? UIDevice.getBundleID())
    }
    
    public static func modelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") {identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
    private static var FileAccountFlag: QueryInitialUserFlag = .unknown
    
    private static let semaphore = DispatchSemaphore.init(value: 1)
    
    private static func PojoMonadHandler(bundleId: String) -> String {
        semaphore.wait()
        let stringUUID = queryUserIdCurrent(bundleId: bundleId)
        semaphore.signal()
        return stringUUID
    }
    
    private static func queryUserIdCurrent(bundleId: String) -> String {
        let key = "\(bundleId).uuid"
        var userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        var userState: QueryInitialUserFlag = .oldUser
        
        let userIdFromKeychain = try? Keychain().get(key) ?? ""
        let userIdFromDisk: String
        if let saver = HXKit.shared.appBase.saver {
            userIdFromDisk = saver.getString(key) ?? ""
        }else {
            userIdFromDisk = UserDefaults.standard.string(forKey: key) ?? ""
        }
        RemoteModule.log(module: .base, content:"[UID] userIdFromKeychain = \(String(describing: userIdFromKeychain)) userIdFromDisk = \(String(describing: userIdFromDisk))")
        if let userIdFromKeychain, !userIdFromKeychain.isEmpty {
            RemoteModule.log(module: .base, content:"[UID] keychain user_id")
            userId = userIdFromKeychain
        } else {
            RemoteModule.log(module: .base, content:"[UID] keychain no user_id，try disk")
            if !userIdFromDisk.isEmpty {
                RemoteModule.log(module: .base, content:"[UID] disk user_id")
                userId = userIdFromDisk
            } else {
                RemoteModule.log(module: .base, content:"[UID] keychain & disk no user_id, new user")
                userState = .newUser
                userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            }
        }
        changeAccountState(newState: userState)
        ReloadSession(key: key, userId: userId)
        return userId
    }
    
    private static func ReloadSession(key: String, userId: String) {
        try? Keychain().set(userId, key: key)
        if let saver = HXKit.shared.appBase.saver {
            saver.saveString(key, userId)
            return
        }
        UserDefaults.standard.setValue(userId, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    private static func changeAccountState(newState: QueryInitialUserFlag) {
        if FileAccountFlag == .unknown {
            FileAccountFlag = newState
        }
    }
    
    public static func isFirstOpen() -> Bool {
        if FileAccountFlag != .unknown {
            return FileAccountFlag == .newUser
        }
        let _ = PojoMonadHandler(bundleId: UIDevice.getBundleID())
        return FileAccountFlag == .newUser
    }
    
    public static func getLocaleCode() -> String {
        let identifier = NSLocale.current.identifier
        let locationId = NSLocale.init(localeIdentifier: identifier)
        return locationId.object(forKey: .countryCode) as! String
    }
    
    public static func getLocaleLanguage() -> String {
        if let language = Bundle.main.preferredLocalizations.first,
            language.count > 0 {
            return language
        } else {
            let language = NSLocale.preferredLanguages[0]
            let languageDictionary = NSLocale.components(fromLocaleIdentifier: language)
            let languageCode = languageDictionary["kCFLocaleLanguageCodeKey"]
            return languageCode ?? ""
        }
    }
    
    public static func getLocalAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    public static func getBundleID() -> String {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    }
    
    public static func getLocalAppBundleVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    
    public static func getSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    public static func getAppName() -> String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
    }
    
    public static func getRequestUUID() -> String {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return "\(formatter.string(from: Date()))-\(NSUUID.init().uuidString)"
    }
}
