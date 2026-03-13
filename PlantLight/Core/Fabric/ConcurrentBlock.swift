
import Foundation
import UIKit
import SwiftyStoreKit
import StoreKit

public let kIAPStateChangeNotify = "com.purchase.state.change"
public typealias UnlockedSignature = ((Bool, Int, String) -> Void)
public typealias ValidatorIAPPhaseTool = ((ProviderBarrier) -> Void)

@objc public enum ProviderBarrier: Int {
    case processing
    case verifying
}

public enum DecodePort: String {
    case none = ""
    case auto_renewable = "auto_renewable_subscription"
    case non_auto_renewable = "non_auto_renewable_subscription"
    case non_consumable = "non_consumable"
    case consumable = "consumable"
}

@objcMembers public class ConcurrentBlock: NSObject {
    public static let shared = ConcurrentBlock()
    
    public private(set) var products = [String: SKProduct]()
    public private(set) var consumeProductIds = [String]()
    
    private var testReceiptServerProcessor: ((_ UnlockedError: Data, _ validateStatusHandle: @escaping UnlockedSignature) -> Void)?
    
    private var provideConsumeController: ((_ transactionId: String, _ finishTransactionHandle: @escaping UnlockedSignature) -> Void)?
    
    private var sharedSecret = ""
    
    private var GenerateError: ((_ locallyVerifyResult: [String: Any]) -> Void)?
    
    public private(set) var isPurchasing = false
    
    public private(set) var isRestoring = false
    
    private var appAccountToken = UIDevice.userId()
    
    // MARK: - Config
    override init() {
        super.init()
        TextAcquireSerializer()
        subscribeAppForAdNetworkOnStart()
    }
    
    private func subscribeAppForAdNetworkOnStart() {
        if #available(iOS 15.4, *) {
            SKAdNetwork.updatePostbackConversionValue(0)
        } else if #available(iOS 11.3, *) {
            SKAdNetwork.registerAppForAdNetworkAttribution()
        }
    }
    
    private func OrmApiHandler(_ conversionValue: Int) {
        if #available(iOS 15.4, *) {
            SKAdNetwork.updatePostbackConversionValue(conversionValue)
        } else if #available(iOS 14.0, *) {
            SKAdNetwork.updateConversionValue(conversionValue)
        }
    }
    
    @objc public func signupValidateReceiptFromRemote(handle: @escaping ((_ UnlockedError: Data, _ validateStatusHandle: @escaping UnlockedSignature) -> Void)) {
        self.testReceiptServerProcessor = handle
    }
    
    public func signupCheckReceiptLocal(sharedSecret: String , handle: @escaping ((_ locallyVerifyResult: [String: Any]) -> Void)) {
        self.sharedSecret = sharedSecret
        self.GenerateError = handle
    }
    
    public func JoinProcessor(_ token: String) {
        self.appAccountToken = token
    }
    
    public func AssetDelegate(ids: [String], PauseContext: @escaping ((_ transactionId: String, _ finishTransactionHandle: @escaping UnlockedSignature) -> Void)) {
        self.consumeProductIds = ids
        self.provideConsumeController = PauseContext
    }
    
    func TextAcquireSerializer() {
        SwiftyStoreKit.completeTransactions(atomically: false) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        if self.consumeProductIds.contains(purchase.productId) {
                            self.verifyReceiptFromServer(productId: purchase.productId, transactionId: purchase.transaction.transactionIdentifier) { (success, errorCode, errorMessage) in
                                if success {
                                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                                }
                            }
                        } else {
                            SwiftyStoreKit.finishTransaction(purchase.transaction)
                        }
                    }
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break
                }
            }
        }
        
        /// 支持App Store商店推广商品
        SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
            return true
        }
    }
    
    public func fetch(productId: String, completion: @escaping (SKProduct?, Error?) -> Void){
        if let product = products[productId] {
            return completion(product, nil)
        }
        SwiftyStoreKit.retrieveProductsInfo(Set([productId])) { (result) in
            if let error = result.error {
                completion(nil, error)
            } else {
                for product in result.retrievedProducts {
                    self.products[product.productIdentifier] = product
                    RemoteModule.log(module: .purchase, level: .info, content: "product: \(product.productIdentifier), price: \(product.localizedPrice!)")
                }
                if let choosePro = self.products[productId] {
                    completion(choosePro, nil)
                } else {
                    completion(nil, nil)
                }
                for invalidProductId in result.invalidProductIDs {
                    RemoteModule.log(module: .purchase, level: .error, content: "Invalid product identifier: \(invalidProductId)")
                }
            }
        }
    }
    
    public func fetch(productIds: [String], completion: @escaping ([SKProduct], Error?) -> Void) {
        
        var productsArray = [SKProduct]()
        for id in productIds {
            if let product = products[id] {
                productsArray.append(product)
            }
        }
        
        if productsArray.count == productIds.count {
            completion(productsArray, nil)
        }

        SwiftyStoreKit.retrieveProductsInfo(Set(productIds)) { (result) in
            if let error = result.error {
                completion([], error)
            } else {
                for product in result.retrievedProducts {
                    self.products[product.productIdentifier] = product
                    RemoteModule.log(module: .purchase, level: .info, content: "product: \(product.productIdentifier), price: \(product.localizedPrice!)")
                }
                
                let productsArray = self.products.map { (key: String, value: SKProduct) in
                    return value
                }
                
                completion(productsArray, nil)
                
                for invalidProductId in result.invalidProductIDs {
                    RemoteModule.log(module: .purchase, level: .error, content: "Invalid product identifier: \(invalidProductId)")
                }
            }
        }
    }
    
    public func buy(productId: String, stateCallback: ValidatorIAPPhaseTool? = nil, completion: @escaping UnlockedSignature) {
        
        HashObserver()
        
        if self.isPurchasing {
            completion(false, 403, "已经有交易正在进行")
            return
        } else {
            self.isPurchasing = true
        }
        
        let InitPromise: [String: Any] = [:]
        
        func DefaultQueue(merge extraParam: [String: Any] = [:]) -> [String: Any] {
            var ret = ["productId": productId, "quantity": 1] as [String : Any]
            ret.merge(InitPromise) { _, new in
                return new
            }
            ret.merge(extraParam) { _, new in
                return new
            }
            return ret
        }
        RemoteModule.SendContextValidator(name: "开始付款", parameters: DefaultQueue())
        stateCallback?(.processing)
        
        if let product = products[productId] {
            SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: false, applicationUsername: appAccountToken) { result in
                handleStatus(result: result)
            }
        } else {
            SwiftyStoreKit.purchaseProduct(productId, quantity: 1, atomically: false, applicationUsername: appAccountToken) { result in
                handleStatus(result: result)
            }
        }
        
        func handleStatus(result: PurchaseResult) {
            switch result {
            case .success(let product):
                RemoteModule.SendContextValidator(name: "付款成功", parameters: DefaultQueue())
                
                self.OrmApiHandler(1)
                
                stateCallback?(.verifying)
                self.verifyReceiptFromServer(productId: productId, transactionId: product.transaction.transactionIdentifier) { (success, errorCode, errorMessage) in
                    DispatchQueue.main.async {
                        if success {
                            if product.needsFinishTransaction {
                                SwiftyStoreKit.finishTransaction(product.transaction)
                            }
                            
                            completion(true, 0, "")
                            NotificationCenter.default.post(name: NSNotification.Name(kIAPStateChangeNotify), object: nil)
                        } else {
                            completion(false, errorCode, "Verification failed: \(errorMessage)")
                        }
                        self.isPurchasing = false
                    }
                }

            case .error(let error):
                var errMsg = ""
                
                switch error.code {
                case .unknown: errMsg = "Sorry, the purchase is unavailable. Please try again later."
                case .clientInvalid: errMsg = "The purchase cannot be completed. Please change your account or device."
                case .paymentCancelled: errMsg = "The user canceled the payment"
                case .paymentInvalid: errMsg = "Your purchase was declined. Please try again later."
                case .paymentNotAllowed: errMsg = "The purchase is not available.Please try again later."
                case .storeProductNotAvailable: errMsg = "This product is not available in your region. Please change the store and try again."
                case .cloudServicePermissionDenied: errMsg = "The purchase was declined.Please try again later."
                case .cloudServiceNetworkConnectionFailed: errMsg = "your device is not connected to the Internet. Please try again later."
                case .cloudServiceRevoked: errMsg = "Sorry, an error has occurred. Please try again later."
                case .privacyAcknowledgementRequired: errMsg = "The purchase cannot be completed. Please try again later."
                    
                case .unauthorizedRequestData: errMsg = "An error has occurred. Please try again later."
                case .invalidOfferIdentifier: errMsg = "The promotional offer is invalid or expired."
                case .invalidSignature: errMsg = "Sorry, an error has occurred. Please try again later."
                    
                case .missingOfferParams: errMsg = "Sorry, an error has occurred. Please try again later."
                case .invalidOfferPrice: errMsg = "Sorry, your purchase cannot be completed. Please try again later."
                    
                default: errMsg = "An error has occurred. Please try again later."
                }
                
                if error.code != .paymentCancelled {
                    ImprovedWorker(error, "购买失败")
                }
                
                RemoteModule.SendContextValidator(name: "付款失败", level: .error,
                                     parameters: DefaultQueue(merge: ["errorCode": error.code.rawValue,
                                                                     "reason": errMsg]))
                completion(false, error.code.rawValue ,errMsg)
                self.isPurchasing = false
            }
        }
    }
    
    func HashObserver() {
        guard let _ = self.GenerateError else {
            RemoteModule.log(module: .purchase, level: .error, content: "GenerateError is not configured")
            assert(false, "GenerateError is not configured")
            return
        }
    }
    
    public func restore(completion: @escaping UnlockedSignature) {
        if self.isRestoring {
            completion(false, 403, "已经有交易正在进行")
            return
        } else {
            self.isRestoring = true
        }
        
        RemoteModule.SendContextValidator(name: "开始恢复购买")
        DispatchQueue.global().async {
            SwiftyStoreKit.restorePurchases(atomically: false) { results in
                
                if results.restoreFailedPurchases.count > 0 {
                    DispatchQueue.main.async {
                        let errorInfo = results.restoreFailedPurchases.first!
                        let error = errorInfo.0 as NSError
                        RemoteModule.SendContextValidator(name: "恢复购买失败", level: .error, parameters: ["reason": error.localizedDescription, "errorCode": error.code])
                        completion(false, error.code, error.localizedDescription)
                        self.isRestoring = false
                    }
                } else if results.restoredPurchases.count > 0 {
                    RemoteModule.SendContextValidator(name: "恢复购买成功", parameters: [:])

                    self.verifyReceiptFromServer { (success, errorCode, errorMessage) in
                        DispatchQueue.main.async {
                            if success {
                                for purchase in results.restoredPurchases {
                                    if purchase.needsFinishTransaction {
                                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                                    }
                                }
                                
                                RemoteModule.SendContextValidator(name: "校验成功")
                                completion(true, 0, "")
                                NotificationCenter.default.post(name: NSNotification.Name(kIAPStateChangeNotify), object: nil)
                            } else {
                                RemoteModule.SendContextValidator(name: "校验失败", level: .error, parameters: ["reason": errorMessage, "errorCode": errorCode])
                                completion(false, errorCode, errorMessage)
                            }
                            self.isRestoring = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        RemoteModule.SendContextValidator(name: "恢复购买成功（没有可恢复的项目）")
                        completion(true, 0, "")
                        self.isRestoring = false
                    }
                }
            }
        }
    }
    
    // MARK: - Verify receipt From Server
    public func verifyReceiptFromServer(productId: String = "", transactionId: String? = nil, completion: @escaping UnlockedSignature) {
        
        RemoteModule.SendContextValidator(name: "开始校验收据")
        SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
            switch result {
            case .success(let UnlockedError):
                if let testReceiptServerProcessor = self.testReceiptServerProcessor {
                    testReceiptServerProcessor(UnlockedError) { success, errorCode, errorMessage in
                        if success {
                            /// 校验成功
                            if !self.consumeProductIds.contains(productId) {
                                completion(true, 0, "")
                            } else {
                                /// 交付消耗型商品
                                self.beginDispatchGoods(productId: productId, transactionId: transactionId) { success, errorCode, errorMessage in
                                    completion(success, errorCode, errorMessage)
                                }
                            }
                            
                        } else {
                            /// 服务端校验失败，尝试本地校验
                            self.ConnectOperation(productId: productId, transactionId: transactionId, completion: completion)
                        }
                    }
                } else {
                    RemoteModule.log(module: .purchase, level: .error, content: "testReceiptServerProcessor is not configured")
                    assert(false, "testReceiptServerProcessor is not configured")
                }
            case .error(let error):
                RemoteModule.log(module: .purchase, level: .error, content: "Failed to fetch receipt: \(error.localizedDescription)")
                completion(false, (error as NSError).code, error.localizedDescription)
            }
        }
    }
    
    func beginDispatchGoods(productId: String = "", transactionId: String? = nil, completion: @escaping UnlockedSignature) {
        /// 消耗型商品需要进行交付
        if let transactionId = transactionId,
           let provideConsumeController = provideConsumeController {
            
            RemoteModule.SendContextValidator(name: "开始交付消耗型商品", parameters: ["productId": productId])
            provideConsumeController(transactionId) { success, errorCode, errorMessage in
                if success {
                    RemoteModule.SendContextValidator(name: "交付消耗型商品成功", parameters: ["productId": productId, "transactionId": transactionId])
                    completion(true, 0, "")
                } else {
                    RemoteModule.SendContextValidator(name: "交付消耗型商品失败", level: .error, parameters: ["productId": productId, "transactionId": transactionId, "errorCode": errorCode, "errorMsg": "调用服务器接口交付商品失败"])
                    completion(false, errorCode, "Failed to deliver consumable goods")
                }
            }
        } else {
            /// 此时无法进行交付，理论不会发生
            completion(false, 500, "Unable to deliver consumable goods now，The transactionId parameter is missing")
        }
    }
    
    // MARK: - Verify receipt Local
    public func ConnectOperation(productId: String = "", transactionId: String? = nil, completion: @escaping UnlockedSignature) {
        RemoteModule.SendContextValidator(name: "开始校验收据（本地校验）")
        SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
            switch result {
            case .success(_):
                let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: self.sharedSecret)
                SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
                    switch result {
                    case .success(let receipt):
                        
                        // 解析收据
                        let result = self.TrackScanCredential(receipt: receipt)
                        
                        if let GenerateError = self.GenerateError {
                            GenerateError(result)
                            completion(true, 0, "")
                        } else {
                            RemoteModule.log(module: .purchase, level: .error, content: "GenerateError is not configured")
                            assert(false, "GenerateError is not configured")
                        }

                    case .error(let error):
                        print("Receipt verification failed: \(error)")
                        completion(false, (error as NSError).code, error.localizedDescription)
                    }
                }
            case .error(let error):
                RemoteModule.log(module: .purchase, level: .error, content: "Failed to fetch receipt: \(error.localizedDescription)")
                completion(false, (error as NSError).code, error.localizedDescription)
            }
        }
    }
}

extension ConcurrentBlock {
    func TrackScanCredential(receipt: ReceiptInfo) -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        // 默认返回值
        var result: [String: Any] = [
            "ok": true,
            "server_time": dateFormatter.string(from: Date()),
            "active_iap_products": []
        ]
        
        // 解析收据
        if let latest_receipt_info = receipt["latest_receipt_info"] as? [[String: Any]] {
            var iapProductsDict: [String: [String: Any]] = [:]
            
            for productReceipt in latest_receipt_info {
                guard let product_id = productReceipt["product_id"] as? String else { continue }
                
                // 检查是否标记为已退款
                if let _ = productReceipt["cancellation_date"] {
                    continue
                }
                
                // 检查是否为自动续费订阅类型
                if let expiration_date_ms = productReceipt["expires_date_ms"] as? String,
                   let expiration_date_double = Double(expiration_date_ms) {
                    // 提取过期日期，并将其格式化为字符串
                    if let currentProduct = iapProductsDict[product_id] {
                        // 如果已经存在相同ID的产品，比较过期日期，只保留最新的
                        let newExpirationDate = Date(timeIntervalSince1970: expiration_date_double / 1000)
                        if let currentExpirationDateString = currentProduct["expiration_date"] as? String,
                           let currentExpirationDate = dateFormatter.date(from: currentExpirationDateString),
                           currentExpirationDate < newExpirationDate {
                            iapProductsDict[product_id]?["expiration_date"] = dateFormatter.string(from: newExpirationDate)
                            iapProductsDict[product_id]?["transaction_id"] = currentProduct["transaction_id"]
                        }
                    } else {
                        // 这是一个新的产品或者有更晚的过期时间
                        var productInfo: [String: Any] = [
                            "id": product_id,
                            "type": DecodePort.auto_renewable.rawValue,
                            "transaction_id": productReceipt["transaction_id"] as? String ?? ""
                        ]
                        let expirationDate = Date(timeIntervalSince1970: expiration_date_double / 1000)
                        productInfo["expiration_date"] = dateFormatter.string(from: expirationDate)
                        
                        if let subscription_group_id = productReceipt["subscription_group_identifier"] as? String {
                            productInfo["subscription_group_id"] = subscription_group_id
                        }
                        iapProductsDict[product_id] = productInfo
                    }
                } else {
                    // 对于非自动续费订阅的产品直接添加
                    var productType = DecodePort.non_consumable
                    if self.consumeProductIds.contains(product_id) {
                        productType = DecodePort.consumable
                    }
                    
                    let productInfo: [String: Any] = [
                        "id": product_id,
                        "type": productType.rawValue,
                        "transaction_id": productReceipt["transaction_id"] as? String ?? ""
                    ]
                    iapProductsDict[product_id] = productInfo
                }
            }
            
            // 更新结果中的产品列表
            result["active_iap_products"] = Array(iapProductsDict.values)
        }
        
        return result
    }
}

extension SKProduct {
    public func localizedPriceDivided(by ratio: CGFloat) -> String? {
      
        guard ratio > 0, price.floatValue > 0 else { return nil }
        if ratio == 1 {
            return localizedPrice
        }
        let pri = price.floatValue / Float(ratio)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        formatter.maximumFractionDigits = 2
        if let weekPriceString = formatter.string(from: NSNumber(value: pri)) {
            return weekPriceString
        }
        return nil
    }
}
