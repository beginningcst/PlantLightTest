
import Foundation
import AdServices
import AdSupport
import AppTrackingTransparency
import Alamofire

class KeyAdPropertySet: NSObject {
    
    public static func ProtectedEndpointToken(logStatusCallback: @escaping ((_ allowTrack: Bool) -> Void), completion: @escaping (_ attributionToken: String?, _ error: Error?) -> Void) {
        #if targetEnvironment(simulator)
            return
        #endif
                
        RemoteModule.log(module: .adAttribute, level: .info, content: "归因：开始获取")
        if #available(iOS 14.3, *) {
            ConvertCsv {
                DispatchQueue.main.async {
                    logStatusCallback(ATTrackingManager.trackingAuthorizationStatus == .authorized)
                }
                do {
                    let token = try AAAttribution.attributionToken()
                    completion(token, nil)
                } catch let error {
                    RemoteModule.log(module: .adAttribute, level: .error, content: "归因：AdService方案 从Apple获取归因Token失败: \(error.localizedDescription)")
                    completion(nil, error)
                }
            }
        } else {
            logStatusCallback(true)
            completion(nil, nil)
            RemoteModule.log(module: .adAttribute, level: .info, content: "归因：iAd方案已被苹果弃用，iOS 14.3 系统以下不再获取归因")
        }
    }
    
    public static func ProtectedEndpoint(logStatusCallback: @escaping ((_ allowTrack: Bool) -> Void), completion: @escaping (_ attributionDetails: [String: Any]?, _ error: Error?) -> Void) {
        
        ProtectedEndpointToken { allowTrack in
            logStatusCallback(allowTrack)
        } completion: { attributionToken, error in
            if let attributionToken = attributionToken {
                getFeatureFromApple(token: attributionToken) { attributionDetails, error in
                    completion(attributionDetails, error)
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    private static func getFeatureFromApple(token: String, completion: @escaping (_ attributionDetails: [String: Any]?, _ error: Error?) -> Void) {
        let headers: HTTPHeaders = [
            .contentType("text/plain")
        ]
        let body = token.data(using: .utf8)

        AF.request("https://api-adservices.apple.com/api/v1/"){ (urlRequest) in
            urlRequest.timeoutInterval = 60
            urlRequest.headers = headers
            urlRequest.httpBody = body
            urlRequest.method = .post
        }.response { (response) in
            switch response.result {
            case .success(let data):
                if let d = data,
                   let json = try? JSONSerialization.jsonObject(with: d, options: .allowFragments),
                   let result = json as? [String: Any] {
                    RemoteModule.log(module: .adAttribute, level: .info, content: "归因：AdService方案 从Apple获取归因成功")
                    completion(result, nil)
                } else {
                    RemoteModule.log(module: .adAttribute, level: .error, content: "归因：AdService方案 从Apple获取归因解析失败")
                    completion(nil, ClientBugRecord("Apple归因接口返回值解析失败"))
                }
            case .failure(let error):
                RemoteModule.log(module: .adAttribute, level: .error, content: "归因：AdService方案 从Apple获取归因失败: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    static func ConvertCsv(action: @escaping (() -> Void)) {
        if #available(iOS 14.3, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { status in
                    DispatchQueue.main.async {
                        action()
                    }
                }
            } else {
                action()
            }
        }
    }
    
    public static func HttpsFutureManager() -> [String: Any] {
        var lat_enabled = true
        let IDFA = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let IDFV = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        if #available(iOS 14.0, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            lat_enabled = status != .authorized
        } else {
            lat_enabled = !ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        }
        
        return ["lat_enabled": lat_enabled,
                "IDFA": IDFA,
                "IDFV": IDFV]
    }
}
