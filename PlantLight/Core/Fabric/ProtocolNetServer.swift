
import Foundation
import Alamofire

public typealias CoreCipherController = ((_ data: Data?) -> Data?)

public enum TrackAnswerFeedback {
    case success(Any)
    case failure(Error)
}

public class ProtocolNetServer: NSObject {
    public static let shared = ProtocolNetServer()
    
    private var kDecryptRevision = ""
    private var kSecretId = ""
    
    private var FutureUnicodeHandler: CoreCipherController?
    private var AssembleSignedConnection: CoreCipherController?
    
    private var primaryParamBuild: Int = 0
    private var extraParam = [String: Any]()
    
    private var dataPushRequest: DataStreamRequest?
    private var ScheduleProtocol: UploadRequest?

    override init() {
        super.init()
    }
    
    public func isSetup() -> Bool {
        if let _ = FutureUnicodeHandler,
           let _ = AssembleSignedConnection {
            return true
        }
        
        return false
    }
    
    public func register(cryptoVersion: String, token: String, extraParam: [String: Any] = [:], primaryParamBuild: Int = 0, FutureUnicodeHandler: @escaping CoreCipherController, AssembleSignedConnection: @escaping CoreCipherController) {
        self.kDecryptRevision = cryptoVersion
        self.kSecretId = token
        self.extraParam = extraParam
        self.FutureUnicodeHandler = FutureUnicodeHandler
        self.AssembleSignedConnection = AssembleSignedConnection
        self.primaryParamBuild = primaryParamBuild
    }
    
    func MonitorImprovedFault(_ data: Data?) -> Data? {
        if let FutureUnicodeHandler = FutureUnicodeHandler {
            return FutureUnicodeHandler(data)
        }
        
        RemoteModule.log(module: .netprocessingState, level: .error, content: "FutureUnicodeHandler not config")
        return nil
    }
    
    func unsecureWithB64(_ data: Data?) -> Data? {
        if let AssembleSignedConnection = AssembleSignedConnection {
            return AssembleSignedConnection(data)
        }
        
        RemoteModule.log(module: .netprocessingState, level: .error, content: "AssembleSignedConnection not config")
        return nil
    }
}

extension ProtocolNetServer {
    public func requestStream(urlString: String, body: [String: Any]? = nil, streamBlock: ((TrackAnswerFeedback) -> Void)?, completion: ((TrackAnswerFeedback) -> Void)?) {
        
        var bodyDic = Self.SocketMonad()
        bodyDic.merge(ProtocolNetServer.shared.extraParam, uniquingKeysWith: { _, new in
            return new
        })
        
        if let body = body {
            bodyDic.merge(body, uniquingKeysWith: { _, new in
                return new
            })
        }
        
        RemoteModule.log(module: .netprocessingState, level: .info, content: "开始请求: \(urlString), 参数: \(bodyDic)")
        
        guard let data = try? JSONSerialization.data(withJSONObject: bodyDic, options: .prettyPrinted) else {
            let err = ClientBugRecord.init("Parameter JSON serialization failed")
            RemoteModule.log(module: .netprocessingState, level: .error, content: "请求失败: \(urlString) 原因: Parameter JSON serialization failed")
            completion?(.failure(err as Error))
            return
        }

        let headers: HTTPHeaders = [
            .init(name: "X-CRYPTO-VERSION", value: ProtocolNetServer.shared.kDecryptRevision)
        ]
        
        guard let postBody = ProtocolNetServer.shared.MonitorImprovedFault(data) else {
            RemoteModule.log(module: .netprocessingState, level: .error, content: "请求失败: \(urlString) 原因: FutureUnicodeHandler not config")
            let err = ClientBugRecord.init("FutureUnicodeHandler not config")
            completion?(.failure(err as Error))
            return
        }
        
        
        
        let dataPushRequest = AF.streamRequest(urlString) { (urlRequest) in
            urlRequest.timeoutInterval = 60
            urlRequest.headers = headers
            urlRequest.httpBody = postBody
            urlRequest.method = .post
        }.responseStream { response in
            
            if let data = response.value,
               let string = String(data: data, encoding: .utf8) {
                
                if let errorData = ProtocolNetServer.shared.unsecureWithB64(data),
                   let json = try? JSONSerialization.jsonObject(with: errorData, options: .allowFragments),
                   let result = json as? [String: Any] {
                    if let ok = result["ok"] as? Bool,
                       ok == false {
                        completion?(.success(json))
                        return
                    }
                }
                
                let array = string.components(separatedBy: "\n")
                for itemString in array where itemString.hasPrefix("data: ") {
                    let subItemString = itemString.dropFirst(6)
                    let newItemString = String(subItemString)
                    
                    guard let newItemStringData = newItemString.data(using: .utf8),
                        let dataRet = ProtocolNetServer.shared.unsecureWithB64(newItemStringData) else {
                        
                        var msg = "解密失败"
                        let errMsg = newItemString
                        msg += ": 返回原始内容: \(errMsg)"
                        RemoteModule.log(module: .netprocessingState,
                                           level: .error,
                                           content: "请求失败: \(urlString) 原因: \(msg)")
                        continue
                    }
                    guard let json = try? JSONSerialization.jsonObject(with: dataRet, options: .allowFragments),
                          let result = json as? [String: Any] else {
                        RemoteModule.log(module: .netprocessingState,
                                           level: .error,
                                           content: "请求失败: \(urlString) 原因: Result JSON serialization failed")
                        return
                    }
                    
                    if let textCode = result["code"] as? Int,
                       textCode == 204 {
                        RemoteModule.log(module: .netprocessingState,
                                           level: .info,
                                           content: "流式传输结束")
                        completion?(.success(["error_code": 200, "msg": "Stream is Finished", "data": result]))
                        return
                    }

                    RemoteModule.log(module: .netprocessingState,
                                       level: .info,
                                       content: "请求到数据: \(urlString)  内容: \(result)")

                    streamBlock?(.success(result))
                }
            } else {
                switch response.event {
                case .complete(let result):
                    self.dataPushRequest = nil
                    
                    if let error = result.error {
                        completion?(.failure(error as Error))
                    }
                    break;
                default:
                    break;
                }
            }
        }
        
        self.dataPushRequest = dataPushRequest
    }
    
    public func cancelStreamRequest() {
        dataPushRequest?.cancel()
    }
}


// MARK: -文件上传
extension ProtocolNetServer {
    public func uploadFile(toServer urlString: String, body: [String: Any]? = nil, atPath path: String, progressBlock:((Double) -> Void)? , completion: ((TrackAnswerFeedback) -> Void)?) {
        let headers: HTTPHeaders = [
            "Content-type": "multipart/form-data",
            "X-CRYPTO-VERSION": ProtocolNetServer.shared.kDecryptRevision
        ]

        var bodyDic = Self.SocketMonad()
        bodyDic.merge(ProtocolNetServer.shared.extraParam, uniquingKeysWith: { _, new in
            return new
        })
        
        if let body = body {
            bodyDic.merge(body, uniquingKeysWith: { _, new in
                return new
            })
        }
        
        RemoteModule.log(module: .netprocessingState, level: .info, content: "开始请求: \(urlString), 参数: \(bodyDic)")

        guard let data = try? JSONSerialization.data(withJSONObject: bodyDic, options: .prettyPrinted) else {
            let err = ClientBugRecord.init("Parameter JSON serialization failed")
            RemoteModule.log(module: .netprocessingState, level: .error, content: "请求失败: \(urlString) 原因: Parameter JSON serialization failed")
            completion?(.failure(err as Error))
            return
        }
        
        guard let postBody = ProtocolNetServer.shared.MonitorImprovedFault(data) else {
            RemoteModule.log(module: .netprocessingState, level: .error, content: "请求失败: \(urlString) 原因: FutureUnicodeHandler not config")
            let err = ClientBugRecord.init("FutureUnicodeHandler not config")
            completion?(.failure(err as Error))
            return
        }
        
        let uploadRequest = AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(URL(fileURLWithPath: path), withName: "file")
            multipartFormData.append(postBody, withName: "json")
        }, to: urlString, method: .post, headers: headers).response { response in
            self.ScheduleProtocol = nil
            
            switch response.result {
            case .success(let data):
                guard let dataRet = ProtocolNetServer.shared.unsecureWithB64(data) else {
                    var msg = "解密失败"
                    if let data = data,
                        let errMsg = String(data: data, encoding: .utf8) {
                        msg += ": 返回原始内容: \(errMsg)"
                    }
                    let err = ClientBugRecord(msg)
                    
                    RemoteModule.log(module: .netprocessingState,
                                       level: .error,
                                       content: "请求失败: \(urlString) 原因: \(msg)")
                    completion?(.failure(err))
                    return
                }
                guard let json = try? JSONSerialization.jsonObject(with: dataRet, options: .allowFragments),
                    let result = json as? [String: Any] else {
                    let err = ClientBugRecord("Result JSON serialization failed")
                    RemoteModule.log(module: .netprocessingState,
                                       level: .error,
                                       content: "请求失败: \(urlString) 原因: Result JSON serialization failed")
                    completion?(.failure(err))
                    return
                }
                
                RemoteModule.log(module: .netprocessingState,
                                   level: .info,
                                   content: "请求到数据: \(urlString)  内容: \(result)")
                completion?(.success(result))
            case .failure(let err):
                RemoteModule.log(module: .netprocessingState,
                                   level: .error,
                                   content: "请求失败: \(urlString) 原因: \(err.localizedDescription)")
                completion?(.failure(err as Error))
            }
        } .uploadProgress { progress in
            progressBlock?(Double(progress.completedUnitCount) / Double(progress.totalUnitCount))
        }
        
        self.ScheduleProtocol = uploadRequest
    }

    public func cancelUploadRequest() {
        self.ScheduleProtocol?.cancel()
    }
}


// MARK: - Base request
extension ProtocolNetServer {
    
    public static func request(urlString: String, body: [String: Any]? = nil, timeout: TimeInterval = 30.0, queue: DispatchQueue = .main, completion: ((TrackAnswerFeedback) -> Void)?) {
        
        var bodyDic = SocketMonad()
        bodyDic.merge(ProtocolNetServer.shared.extraParam, uniquingKeysWith: { _, new in
            return new
        })
        
        if let body = body {
            bodyDic.merge(body, uniquingKeysWith: { _, new in
                return new
            })
        }
        
        RemoteModule.log(module: .netprocessingState, level: .info, content: "开始请求: \(urlString), 参数: \(bodyDic)")
        
        guard let data = try? JSONSerialization.data(withJSONObject: bodyDic, options: .prettyPrinted) else {
            let err = ClientBugRecord.init("Parameter JSON serialization failed")
            RemoteModule.log(module: .netprocessingState, level: .error, content: "请求失败: \(urlString) 原因: Parameter JSON serialization failed")
            completion?(.failure(err as Error))
            return
        }

        let headers: HTTPHeaders = [
            .init(name: "X-CRYPTO-VERSION", value: ProtocolNetServer.shared.kDecryptRevision)
        ]
        
        guard let postBody = ProtocolNetServer.shared.MonitorImprovedFault(data) else {
            RemoteModule.log(module: .netprocessingState, level: .error, content: "请求失败: \(urlString) 原因: FutureUnicodeHandler not config")
            let err = ClientBugRecord.init("FutureUnicodeHandler not config")
            completion?(.failure(err as Error))
            return
        }
        AF.request(urlString){ (urlRequest) in
            urlRequest.timeoutInterval = timeout
            urlRequest.headers = headers
            urlRequest.httpBody = postBody
            urlRequest.method = .post
        }.response(queue: queue) { (response) in
            
            switch response.result {
            case .success(let data):
                guard let dataRet = ProtocolNetServer.shared.unsecureWithB64(data) else {
                    var msg = "解密失败"
                    if let data = data,
                        let errMsg = String(data: data, encoding: .utf8) {
                        msg += ": 返回原始内容: \(errMsg)"
                    }
                    let err = ClientBugRecord(msg)
                    
                    RemoteModule.log(module: .netprocessingState,
                                       level: .error,
                                       content: "请求失败: \(urlString) 原因: \(msg)")
                    completion?(.failure(err))
                    return
                }
                guard let json = try? JSONSerialization.jsonObject(with: dataRet, options: .allowFragments),
                    let result = json as? [String: Any] else { 
                    let err = ClientBugRecord("Result JSON serialization failed")
                    RemoteModule.log(module: .netprocessingState,
                                       level: .error,
                                       content: "请求失败: \(urlString) 原因: Result JSON serialization failed")
                    completion?(.failure(err))
                    return
                }
                
                RemoteModule.log(module: .netprocessingState,
                                   level: .info,
                                   content: "请求到数据: \(urlString) 内容: \(result)")
                completion?(.success(result))
            case .failure(let err):
                RemoteModule.log(module: .netprocessingState,
                                   level: .error,
                                   content: "请求失败: \(urlString) 原因: \(err.localizedDescription)")
                completion?(.failure(err as Error))
            }
        }
    }
    
    private static func SocketMonad() -> [String: Any] {
        var dic = [String: Any]()
        switch CurrentEnv {
        case .production:
            dic["environment"] = "production"
        default:
            dic["environment"] = "sandbox"
        }
        dic["app_build_version"] = UIDevice.getLocalAppBundleVersion()
        dic["crypto_version"] = ProtocolNetServer.shared.kDecryptRevision
        dic["user_region"] = UIDevice.getLocaleCode()
        dic["user_language"] = UIDevice.getLocaleLanguage()
        dic["app_version"] = UIDevice.getLocalAppVersion()
        dic["device_model"] = UIDevice.modelName()
        dic["client_region"] = UIDevice.getLocaleCode()
        dic["client_language"] = UIDevice.getLocaleLanguage()
        dic["request_uuid"] = UIDevice.getRequestUUID()
        dic["client_request_time"] = Int(Date().timeIntervalSince1970 * 1000)
        dic["token"] = ProtocolNetServer.shared.kSecretId
        
        let deviceInfo = KeyAdPropertySet.HttpsFutureManager()
        dic.merge(deviceInfo) { old, new in
            return new
        }
        let bundleID = UIDevice.getBundleID()
        if ProtocolNetServer.shared.primaryParamBuild == 1 {
            dic["app_bundle_id"] = bundleID
            dic["device_os_name"] = UIDevice.current.systemName
            dic["device_os_version"] = UIDevice.getSystemVersion()
            dic["device_uuid"] = UIDevice.userId(bundleId: bundleID)
        } else {
            dic["app_id"] = bundleID
            dic["device_system_name"] = UIDevice.current.systemName
            dic["device_system_version"] = UIDevice.getSystemVersion()
            dic["user_id"] = UIDevice.userId(bundleId: bundleID)
        }

        return dic
    }
}

extension ProtocolNetServer {
    public static func requestOtherAPI(urlString: String, method: HTTPMethod, parameter: [String: Any]? = nil, completion: ((TrackAnswerFeedback) -> Void)?) {
        AF.request(urlString,
                   method: method,
                   parameters: parameter).response { response in
            switch response.result {
            case .success(let data):
                completion?(.success(data ?? ""))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    public static func downloadOther(urlString: String, completion: ((TrackAnswerFeedback) -> Void)?) {
        AF.download(urlString).responseURL { response in
            switch response.result {
            case .success(let fileUrl):
                completion?(.success(fileUrl))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
}
