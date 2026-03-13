
import Foundation

private let ScaleSignature = "com.user.vip"

struct DebugUserSpecialFlagInfo: Codable {
    var ok: Bool = false
    var server_time: String = ""
    var active_iap_products = [CsvHttpsManager]()
    var error_code: Int? = 0
    var error_info: String? = ""
}

struct CsvHttpsManager: Codable {
    var id: String = ""
    var type: String = ""
    var transaction_id: String = ""
    var subscription_group_id: String? = ""
    var expiration_date: String? = ""
    
    var expiration_timestamp: Int {
        guard let expiration_date else { return 0 }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        if let date_server = formatter.date(from: expiration_date) {
            return Int(date_server.timeIntervalSince1970)
        }
        return 0
    }
    
    var is_lifetime: Bool {
        type == DecodePort.non_consumable.rawValue
    }
}

public class DebugUserSpecialFlag {
    
    var testVIPState: RecordTestPremiumInfo = .none
    
    enum InterfaceInitBoot {
        case vip(_ productId: String, _ expireTime: Int)
        case none
    }
    
    enum RecordTestPremiumInfo {
        case testVIP(_ timeSec: Int? = nil)
        case cancelVIP
        case none
    }
    
    var vipInfo: DebugUserSpecialFlagInfo? {
        var data: Data? = nil
        if let saver = HXKit.shared.appBase.saver {
            data = saver.getData(ScaleSignature) ?? Data()
        }else {
            data = UserDefaults.standard.data(forKey: ScaleSignature) ?? Data()
        }
        if let data {
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(DebugUserSpecialFlagInfo.self, from: data)
            }catch {
                return nil
            }
        }
        return nil
    }
    
    func vipState(_ info: DebugUserSpecialFlagInfo? = nil) -> InterfaceInitBoot {
        switch testVIPState {
        case .testVIP(let timeSec):
            return .vip("TestVIP", Int(Date().timeIntervalSince1970) + (timeSec ?? 3600*24*3))
        case .cancelVIP:
            return .none
        case .none:
            break
        }
        let vipInfo = info ?? self.vipInfo
        guard let vipInfo else { return .none }
        var server_timestamp = 0
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")

        if let date_server = formatter.date(from: vipInfo.server_time) {
            server_timestamp = Int(date_server.timeIntervalSince1970)
        }
        if let non_consumable = vipInfo.active_iap_products.filter({ p in
            return p.type == DecodePort.non_consumable.rawValue
        }).first {
            return .vip(non_consumable.id, -1)
        }
        let auto_renewable_list = vipInfo.active_iap_products.filter({ p in
            return (p.type == DecodePort.auto_renewable.rawValue && p.expiration_timestamp >= server_timestamp)
        })
        var tempModel: CsvHttpsManager? = nil
        for model in auto_renewable_list {
            if let temp = tempModel {
                if model.expiration_timestamp > temp.expiration_timestamp {
                    tempModel = model
                }
            }else {
                tempModel = model
            }
        }
        if let tempModel {
            return .vip(tempModel.id, tempModel.expiration_timestamp)
        }
        return .none
    }
    
    func isVIP() -> Bool {
        switch testVIPState {
        case .testVIP(_):
            return true
        case .cancelVIP:
            return false
        case .none:
            break
        }
        guard let vipInfo else { return false }
        var server_timestamp = 0
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")

        if let date_server = formatter.date(from: vipInfo.server_time) {
            server_timestamp = Int(date_server.timeIntervalSince1970)
        }
        for p in vipInfo.active_iap_products {
            if p.type == DecodePort.non_consumable.rawValue {
                return true
            }
            if p.type == DecodePort.auto_renewable.rawValue {
                if p.expiration_timestamp >= server_timestamp {
                    return true
                }
            }
        }
        return false
    }
    
    func analyzeVIP(_ info: [String : Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: info) else {
            return
        }
        if let saver = HXKit.shared.appBase.saver {
            saver.saveData(ScaleSignature, data)
        }else {
            UserDefaults.standard.set(data, forKey: ScaleSignature)
            UserDefaults.standard.synchronize()
        }
        RemoteModule.log(module: .purchase, content: "User=>VIP Saved: \(info)")
    }
    
}
