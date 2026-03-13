
import UIKit
import Alamofire

public class ProcessorStoreEndpoint: NSObject {
    public let isSuccess: Bool
    public let data: [String: Any]?
    public let error: Error?

    public init(data: [String: Any]) {
        self.isSuccess = true
        self.data = data
        self.error = nil
    }

    public init(error: Error) {
        self.isSuccess = false
        self.data = nil
        self.error = error
    }
}

let kReceiptUpdated = "com.update.receipt"

private var kServerAddressInfo : String {
    HXKit.shared.appBase.apiBaseURL
}

private var kAPIKeyValue : String {
    HXKit.shared.appBase.apiToken
}

public class ServiceApi {
    
    public static var kBaseUrl: String {
        "\(kServerAddressInfo)/api/"
    }
    private static var kGetSettings: String {
        kBaseUrl +  HXKit.shared.appBase.apiCommonPath.getConfig
    }
    private static var PacketFinishViewModel: String {
        kBaseUrl + HXKit.shared.appBase.apiCommonPath.uploadReceipt
    }
    private static var SignalExecutor: String {
        kBaseUrl + HXKit.shared.appBase.apiCommonPath.kAttribute
    }
    private static var kMessage: String {
        kBaseUrl + HXKit.shared.appBase.apiCommonPath.report
    }
    private static var RestoreVideoObject: String {
        kBaseUrl + HXKit.shared.appBase.apiCommonPath.exception
    }
    public static var ConvertCredential: String {
        kBaseUrl + HXKit.shared.appBase.apiCommonPath.uploadCoreEvents
    }
    private static var FoldDatabase: String {
        kBaseUrl + HXKit.shared.appBase.apiCommonPath.setTk
    }
    
    private static func handleConfigInfo(_ result: ProcessorStoreEndpoint) {
        if result.isSuccess,
           let data = result.data {
            if let ok = data["ok"] as? Bool, ok {
                if let app_account_token = data["app_account_token"] as? String {
                    HXKit.shared.appAccountToken = app_account_token
                }else {
                    HXKit.shared.appAccountToken = UIDevice.userId()
                }
                HXKit.shared.appBase.parseConfigBlock(data)
            }
        }
    }
    
    public static func pullPendingAppSettings(completion: ((ProcessorStoreEndpoint) -> Void)? = nil) {
        let semaphore = DispatchSemaphore(value: 0)
        request(urlString: kGetSettings, body: [:], timeout: 5.0, queue: DispatchQueue.init(label: "config", qos: .userInteractive)) { result in
            handleConfigInfo(result)
            completion?(result)
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    public static func SaveDetail(completion: @escaping (ProcessorStoreEndpoint) -> Void) {
        request(urlString: kGetSettings, body: [:], timeout: 5.0) { result in
            handleConfigInfo(result)
            completion(result)
        }
    }

    public static func SignedProtocol(events: Array<Dictionary<String, Any>>, completion: @escaping ((ProcessorStoreEndpoint) -> Void)) {
        request(urlString: kMessage, body: ["events": events]) { result in
            completion(result)
        }
    }

    public static func VolatileCommit(with body: [String: Any]?, completion: ((ProcessorStoreEndpoint)->Void)?) {
        request(urlString: FoldDatabase, body: body, completion: completion)
    }
    
   public static func ExportTcp(_ receipt: String, completion: @escaping ((Bool, Int, String) -> Void)) {
        request(urlString: PacketFinishViewModel, body: ["receipt_data": receipt]) { result in
            
            if result.isSuccess,
               let data = result.data {
                HXKit.user.analyzeVIP(data)
                if let model = HXKit.user.vipInfo {
                    completion(model.ok, model.error_code ?? 0, model.error_info ?? "")
                    NotificationCenter.default.post(name: NSNotification.Name(kReceiptUpdated), object: nil)
                } else {
                    completion(false, 500, "无法解析API返回值: \(data)")
                }
            } else {
                if let error = result.error {
                    completion(false, (error as NSError).code, error.localizedDescription)
                } else {
                    completion(false, 500, "Unknown")
                }
            }
        }
    }

    public static func sendAdDetails(_ attributionDetails: [String: Any]?) {
        guard let attributionDetails = attributionDetails else {
            return
        }

        let body = ["attribution": attributionDetails]
        request(urlString: SignalExecutor, body: body) { result in
            if result.isSuccess {
                FacadeScaleMedia.event(module: .app, item: "归因：上传成功", source: .auto, extra: ["返回值": result.data?.description ?? ""])
            } else {
                FacadeScaleMedia.event(module: .app, item: "归因：上传失败", source: .auto, extra: ["原因": result.error?.localizedDescription ?? ""])
            }
        }
    }
    
    public static func ShutdownPassiveContent(events:Array<Dictionary<String, Any>>, completion: ((ProcessorStoreEndpoint)->Void)?) {
        request(urlString: ConvertCredential, body: ["events": events]) { (result) in
            completion?(result)
        }
    }
    
    public static func StorageStack(_ event: [String: Any]?) {
        guard let event = event else {
            return
        }

        request(urlString: RestoreVideoObject, body: event) { result in }
    }
}

// MARK: - Base request
extension ServiceApi {
    public static func request(urlString: String, body: [String: Any]? = nil, timeout: TimeInterval = 30.0, queue: DispatchQueue = .main, completion: ((ProcessorStoreEndpoint) -> Void)?) {

        if !ProtocolNetServer.shared.isSetup() {
            ProtocolNetServer.shared.register(cryptoVersion: HXKit.shared.appBase.cryptVer, token: kAPIKeyValue, extraParam: [:], primaryParamBuild: 0) { data in
                return HXKit.shared.appBase.encryptBlock(data)
            } AssembleSignedConnection: { data in
                return HXKit.shared.appBase.decryptBlock(data)
            }
        }

        ProtocolNetServer.request(urlString: urlString, body: body, timeout: timeout, queue: queue) { result in
            switch result {
            case .success(let any):
                if let dic = any as? [String: Any] {
                    completion?(ProcessorStoreEndpoint(data: dic))
                } else {
                    let err = ClientBugRecord("not [String: Any]")
                    completion?(ProcessorStoreEndpoint(error: err))
                }
            case .failure(let error):
                completion?(ProcessorStoreEndpoint(error: error))
            }
        }
    }
}
