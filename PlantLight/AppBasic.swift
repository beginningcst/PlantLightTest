import YYModel
import MMKV

var IsLocalMode: Bool = CurrentEnv != .production

struct Constant {
    static let bundleId = "com.safecura.plant"
    static let apiHost = "https://plant.safecura.com"
    static let apiBaseURL = "\(apiHost)"
    static let termURL = "https://clean.safecura.com/terms"
    static let policyURL = "https://clean.safecura.com/privacy"
}

extension Constant {
    static let appstoreId = "6755172069"
    static let supportEmail = "support@safecura.com"
}

class Config: NSObject {
    @objc var rate_popup_count: Int = 1
    @objc var rate_popup_percent: Int = 100
    @objc var rate_popup_position: String?
   
    @objc var version_info: VersionInfo = VersionInfo()
    @objc var email_support: EmailSupport = EmailSupport()
    @objc var log_time_interval: Int = 5
    @objc var log_max_cache: Int = 30
    @objc var localization: [String: String]?
    @objc var common_guide_url: String = "\(Constant.apiHost)/pages/measurement_values.html"
    
    enum RateWhere: String {
        case start
        case tab
    }
    
    class VersionInfo: NSObject {
        @objc var appstoreId: String = Constant.appstoreId
        @objc var url: String = "https://apps.apple.com/us/app/id\(Constant.appstoreId)"
        @objc var isForce: Int = 0
        @objc var text: String = ""
        @objc var name: String = ""
        @objc var code: Int = 0
    }
    
    class EmailSupport: NSObject {
        @objc var support_content: String = "#deviceId#"
        @objc var email: String = Constant.supportEmail
    }
}

extension AppBasic {
    @SV(key:"app_rate_times", def: 0) static var useRateTimes: Int
    @SV(key:"app_is_agree_show", def: false) static var isAgreeShow: Bool
}

private let kAppBaseConfigSaveKey = "com.safecura.app.xconfig"

class AppBasic {
    
    static let shared = AppBasic()
    
    private var configModel: Config?
    
    static var config: Config {
        if let configModel = shared.configModel {
            return configModel
        }
        //从本地取
        guard let data = Self.shared.saver?.getDict(kAppBaseConfigSaveKey), let configModel = Config.yy_model(with: data) else {
            //返回default
            let model = Config()
            shared.configModel = model
            return model
        }
        shared.configModel = configModel
        return configModel
    }
    private var _saver = Saver()
}

extension AppBasic: HXAppBase {
    
    var apiToken: String {
        "vH8qM2rY4tC9kB0pE3sJ5nL1aW6dX7u"
    }
    
    var apiCommonPath: (getConfig: String, uploadReceipt: String, kAttribute: String, report: String, exception: String, uploadCoreEvents: String, setTk: String) {
        (
         getConfig: "w1YF4GmQ8rE5vS9nH2Tj0BzXkN7aP3uC",
         uploadReceipt: "nX4aU6D9yV3tJ5pR1bS2qE8zL0wK7fH",
         kAttribute: "tA9fR5W8yK2nC0pS6bQ7vX4jE1zD3uL",
         report: "mZ7rL2N4eV1aQ8tS3kW9pY5hX0dC6uB",
         exception: "uT5xY9nP2vC6kD0rB7eH1qL8mW3sA4f",
         uploadCoreEvents: "pE4kX1vL7rD8tN9jY0qC2sM6bF3aW5u",
         setTk: "zJ3aN7vB9kR5qX0mL6tC1pY8eD2sW4h"
        )
    }
    
    var bundleID: String {
        Constant.bundleId
    }
    
    var iapSharedSecret: String {
        ""
    }
    
    var apiBaseURL: String {
        Constant.apiBaseURL
    }
    
    var parseConfigBlock: ([String : Any]) -> Void {
        {
            data in
            Self.shared.saver?.saveDict(kAppBaseConfigSaveKey, data)
            let result = Config.yy_model(with: data)
            Self.shared.configModel = result
        }
    }
    
    var serverLocalizationBlock: ((String) -> String?)? {
        {
            key in
            Self.config.localization?[key] as? String
        }
    }
    
    var productIds: [String] {
        []
    }
    
    var logSendInterval: Int {
        Self.config.log_time_interval
    }
    
    var logMaxCache: Int {
        Self.config.log_max_cache
    }
    
    var saver: (any HXSaver)? {
        return _saver
    }
}

struct Saver: HXSaver {
    
    init() {
        MMKV.initialize(rootDir: nil)
    }
    
    func saveData(_ key: String, _ value: Data) {
        MMKV.default()?.set(value, forKey: key)
    }
    
    func getData(_ key: String) -> Data? {
        MMKV.default()?.data(forKey: key)
    }
    
    func saveString(_ key: String, _ value: String) {
        MMKV.default()?.set(value, forKey: key)
    }
    
    func getString(_ key: String) -> String? {
        MMKV.default()?.string(forKey: key)
    }
}

extension HXSaver {
    
    func saveInt(_ key: String, _ value: Int) {
        MMKV.default()?.set(Int64(value), forKey: key)
    }
    
    func getInt(_ key: String, defaultValue: Int = 0) -> Int {
        Int(MMKV.default()?.int64(forKey: key, defaultValue: Int64(defaultValue)) ?? Int64(defaultValue))
    }
    
    func saveBool(_ key: String, _ value: Bool) {
        MMKV.default()?.set(value, forKey: key)
    }
    
    func getBool(_ key: String, defaultValue: Bool = false) -> Bool {
        MMKV.default()?.bool(forKey: key, defaultValue: defaultValue) ?? defaultValue
    }
    
    func saveDict(_ key: String, _ value: [String: Any]) {
        MMKV.default()?.set(value as NSDictionary, forKey: key)
    }
    
    func getDict(_ key: String) -> [String: Any]? {
        MMKV.default()?.object(of: NSDictionary.self, forKey: key) as? [String : Any]
    }
    
    func saveArr(_ key: String, _ value: [Any]) {
        MMKV.default()?.set(value as NSArray, forKey: key)
    }
    
    func getArr(_ key: String) -> [Any]? {
        MMKV.default()?.object(of: NSArray.self, forKey: key) as? [Any]
    }
    
    func saveObj<T: Codable>(_ key: String, _ value: T) {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(value)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                MMKV.default()?.set(jsonString, forKey: key)
            }
        } catch {
        }
    }
    
    func getObj<T: Codable>(_ key: String, objectType: T.Type) -> T? {
        guard let jsonString = MMKV.default()?.string(forKey: key),
              let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: jsonData)
        } catch {
            return nil
        }
    }
    
    func clearAll() {
        MMKV.default()?.clearAll()
    }
}

@propertyWrapper
struct SV<T> {
    private var key: String
    private var defaultValue: T
    
    init(key: String, def: T) {
        self.key = key
        self.defaultValue = def
    }
    
    var wrappedValue: T {
        get {
            if T.self == Bool.self {
                return AppBasic.shared.saver?.getBool(key, defaultValue: defaultValue as? Bool ?? false) as? T ?? defaultValue
            }else if T.self == Int.self {
                return AppBasic.shared.saver?.getInt(key, defaultValue: defaultValue as? Int ?? 0) as? T ?? defaultValue
            } else if T.self == String.self {
                return AppBasic.shared.saver?.getString(key) as? T ?? defaultValue
            }else if T.self == Dictionary<String, Any>.self {
                return AppBasic.shared.saver?.getDict(key) as? T ?? defaultValue
            }else if T.self == Array<Any>.self {
                return AppBasic.shared.saver?.getArr(key) as? T ?? defaultValue
            }
            return defaultValue
        }
        set {
            if T.self == Bool.self {
                guard let boolValue = newValue as? Bool else { return }
                AppBasic.shared.saver?.saveBool(key, boolValue)
            } else if T.self == Int.self {
                guard let intValue = newValue as? Int else { return }
                AppBasic.shared.saver?.saveInt(key, intValue)
            } else if T.self == String.self {
                guard let strValue = newValue as? String else { return }
                AppBasic.shared.saver?.saveString(key, strValue)
            }else if T.self == Dictionary<String, Any>.self {
                guard let dictValue = newValue as? Dictionary<String, Any> else { return }
                AppBasic.shared.saver?.saveDict(key, dictValue)
            }else if T.self == Array<Any>.self {
                guard let arrValue = newValue as? Array<Any> else { return }
                AppBasic.shared.saver?.saveArr(key, arrValue)
            }
        }
    }
}
