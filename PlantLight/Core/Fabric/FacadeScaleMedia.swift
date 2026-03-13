
import UIKit
import StoreKit

public protocol TextCssHandler {
    var description: String { get }
}

public enum StatsModule {
    case app
    case page(_ page: TextCssHandler)
    case dialog(_ page: TextCssHandler, _ name: String)
}

private extension StatsModule {
    var description: String {
        get {
            switch (self) {
            case .app:
                return "应用程序"
            case .dialog(let module, let name):
                return "\(module.description)-\(name)"
            case .page(let page):
                return "\(page.description)"
            }
        }
    }
}

@objc public enum CaptureSource: Int {
    case user
    case auto
}

private extension CaptureSource {
    var description: String {
        get {
            switch (self) {
            case .user:
                return "用户"
            case .auto:
                return "程序"
            }
        }
    }
}

public enum InteractionAction {
    case none
    case state(_ parameters: [String: Any]) // 状态
    
    case showDialog(_ parameters: [String: Any]) // 显示
    case hideDialog(_ parameters: [String: Any]) // 隐藏
    
    case willEnter // 准备进入
    case didEnter(_ parameters: [String: Any] = [:]) // 已经进入
    case leave(_ parameters: [String: Any] = [:]) // 离开
    
    case willRequest(_ what: String, _ parameters: [String: Any]) // 准备请求某一个内容
    case didRequest(_ what: String, _ success: Bool, _ parameters: [String: Any]) // 请求内容
    
    case willRestore
    case didRestore(_ success: Bool, _ parameters: [String: Any]) // 还原某一个内容成功
    
    case willPurchase(_  what: String, _ parameters: [String: Any])
    case didPurchase(_  what: String, _ success: Bool, _ parameters: [String: Any])
    
    case willDeliveryProduct(_  what: String, _ transactionId: String, _ parameters: [String: Any])
    case didDeliveryProduct(_  what: String, _ transactionId: String, _ success: Bool, _ parameters: [String: Any])
    
    case willVerify
    case didVerify(_ success: Bool, _ parameters: [String: Any])
    
    case click(_ what: String, _ parameters: [String: Any])  // 点击
    case clickPay(_ parameters: [String: Any])  // 点击
    case delete(_ what: String, _ parameters: [String: Any])
    
    case select(_ what: String, _ parameters: [String: Any])//选择
    case event(_ what: String, _ parameters: [String: Any])
}

private extension InteractionAction {
    var description: String {
        get {
            switch (self) {
            case.none:
                return ""
            case .state(let state):
                return "当前状态 : \(state)"
            case .showDialog(let content):
                return "显示对话框 : \(content)"
            case .hideDialog(let what):
                return "隐藏对话框 : \(what)"
            case .willEnter:
                return "即将进入"
            case .didEnter:
                return "已进入"
            case .leave:
                return "已离开"
            case .willRequest(let what, _):
                return "准备请求内容 : \(what)"
            case .didRequest(let what, _, _):
                return "获得请求内容 : \(what)"
            case .willRestore:
                return "开始恢复购买"
            case .didRestore(let success, let info):
                if !success {
                    return "恢复购买失败: \(info)"
                }
                return "恢复购买成功 \(info)"
            case .click(let target, let info):
                return "点击 : \(target) \(info)"
            case .clickPay(_):
                return "购买点击"
            case .delete(let deleteWhat, _):
                return "已删除 : \(deleteWhat)"
            case .willPurchase(let productId, _):
                return "开始付款: \(productId)"
            case .didPurchase(let productId, let success, let reason):
                if !success {
                    return "付款失败：\(productId) 原因：\(reason)"
                }
                return "付款成功：\(productId)"
            case .willDeliveryProduct(let productId, let transactionId, _):
                return "开始交付消耗型商品: \(productId) 交易id: \(transactionId)"
            case .didDeliveryProduct(let productId, let transactionId, let success, let reason):
                if !success {
                    return "交付消耗型商品失败：\(productId) 交易id: \(transactionId) 原因：\(reason)"
                }
                return "交付消耗型商品成功：\(productId) 交易id: \(transactionId)"
            case .willVerify:
                return "开始校验"
            case .didVerify(let success, let reason):
                if !success {
                    return "校验失败 原因：\(reason)"
                }
                return "校验成功 \(reason)"
            case .select(let what, _):
                return "勾选 : \(what)"
            case .event(let target, let info):
                return "事件 : \(target) \(info)"
            }
        }
    }
}

public class FacadeScaleMedia: NSObject {
    
    public static func app(state: String) {
        FacadeScaleMedia.event(module: .app, source: .user, action: .state(["应用状态": state]))
    }
    
    public static func permission(of permission: String, state: String) {
        FacadeScaleMedia.event(module: .app, source: .auto, action: .state(["权限": permission, "权限状态": state]))
    }
    
    public static func subscriptionWillRestore() {
        FacadeScaleMedia.event(module: .app, source: .auto, action: .willRestore)
    }
    
    public static func subscriptionDidRestore(validate: Bool, error: NSError?, restoreCount: Int) {
        if validate {
            if restoreCount > 0 {
                FacadeScaleMedia.event(module: .app, source: .auto, action: .didRestore(validate, [:]))
            } else {
                FacadeScaleMedia.event(module: .app, source: .auto, action: .didRestore(validate, ["结果" : "没有需要恢复的购买项目"]))
            }
        } else {
            if let error = error {
                FacadeScaleMedia.event(module: .app, source: .auto, action: .didRestore(validate, ["错误原因": error.localizedDescription, "code": error.code]))
            } else {
                FacadeScaleMedia.event(module: .app, source: .auto, action: .didRestore(validate, [:]))
            }
        }
    }
    
    public static func subscription(subscribed: Bool) {
        FacadeScaleMedia.event(module: .app, source: .auto, action: .state(["购买状态": subscribed ? "已购买" : "未购买"]))
    }
    
    public static func subscriptionStartPurchase(identifier: String, extra: [String: Any] = [:]) {
        FacadeScaleMedia.event(module: .app, source: .user, action: .willPurchase(identifier, extra))
    }
    
    public static func subscriptionStartPurchase(identifier: String, page: TextCssHandler, tag: String, extra: [String: Any]) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .willPurchase(identifier, extra), tag: tag)
    }
    
    public static func subscriptionEndPurchase(identifier: String, success: Bool, error: NSError?) {
        if let error = error {
            FacadeScaleMedia.event(module: .app, source: .user, action: .didPurchase(identifier, success, ["错误原因": error.localizedDescription, "code": error.code]))
        } else {
            FacadeScaleMedia.event(module: .app, source: .user, action: .didPurchase(identifier, success, [:]))
        }
    }
    
    public static func subscriptionEndPurchase(identifier: String, page: TextCssHandler, tag: String, success: Bool, extra: [String: Any]) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .didPurchase(identifier, success, extra), tag: tag)
    }
    
    public static func consumeStartDelivery(identifier: String, transactionId: String) {
        FacadeScaleMedia.event(module: .app, source: .user, action: .willDeliveryProduct(identifier, transactionId, [:]))
    }
    
    public static func consumeEndDelivery(identifier: String, transactionId: String, success: Bool, error: NSError?) {
        if let error = error {
            FacadeScaleMedia.event(module: .app, source: .user, action: .didDeliveryProduct(identifier, transactionId, success, ["错误原因": error.localizedDescription, "code": error.code]))
        } else {
            FacadeScaleMedia.event(module: .app, source: .user, action: .didDeliveryProduct(identifier, transactionId, success, [:]))
        }
    }
    
    public static func subscriptionStartVerify() {
        FacadeScaleMedia.event(module: .app, source: .user, action: .willVerify)
    }
    
    public static func subscriptionEndVerify(success: Bool, error: String?) {
        if !success  {
            FacadeScaleMedia.event(module: .app, source: .user, action: .didVerify(success, ["错误原因": error ?? "请求校验收据接口错误"]))
        } else {
            FacadeScaleMedia.event(module: .app, source: .user, action: .didVerify(success, [:]))
        }
    }
    
    public static func pageWillEnter(_ page: TextCssHandler) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .willEnter)
    }
    
    public static func pageDidEnter(_ page: TextCssHandler) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .didEnter())
    }
    
    public static func pageDidEnter(_ page: TextCssHandler, tag: String, parameters: [String: Any]) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .didEnter(parameters), tag: tag)
    }
    
    public static func pageDidLeave(_ page: TextCssHandler) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .leave())
    }
    
    public static func pageDidLeave(_ page: TextCssHandler, tag: String, parameters: [String: Any]) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .leave(parameters), tag: tag)
    }
    
    public static func page(page: TextCssHandler, willRequest what: String, source: CaptureSource = .user) {
        FacadeScaleMedia.event(module: .page(page), source: source, action: .willRequest(what, [:]))
    }
    
    public static func page(page: TextCssHandler, didRequest what: String, content: Any? = nil, source: CaptureSource = .user) {
        if let content = content {
            FacadeScaleMedia.event(module: .page(page), source: source, action: .didRequest(what, true, ["内容": content]))
        } else {
            FacadeScaleMedia.event(module: .page(page), source: source, action: .didRequest(what, true, [:]))
        }
    }
    
    public static func didRequest(item: String, success: Bool, content:String){
        FacadeScaleMedia.event(module: .app, source: .auto, action: .didRequest(item, success, success ? ["内容": content] : [:]))
    }
    
    public static func willRequest(item: String){
        FacadeScaleMedia.event(module: .app, source: .auto, action: .willRequest(item, [:]))
    }
    
    public static func page(page: TextCssHandler, didFailRequest what: String, source: CaptureSource = .user) {
        FacadeScaleMedia.event(module: .page(page), source: source, action: .didRequest(what, false, [:]))
    }
    
    public static func dialog(withName name: String, showIn page: TextCssHandler) {
        FacadeScaleMedia.event(module: .dialog(page, name), source: .user, action: .showDialog([:]))
    }
    
    public static func dialog(withName name: String, hideIn page: TextCssHandler) {
        FacadeScaleMedia.event(module: .dialog(page, name), source: .user, action: .hideDialog([:]))
    }
    
    public static func dialog(_ dialog: UIAlertController, showIn page: TextCssHandler) {
        FacadeScaleMedia.event(module: .dialog(page, dialog.title ?? dialog.message ?? "对话框"), source: .user, action: .showDialog([:]))
    }
    
    public static func dialog(_ dialog: UIAlertController, hideIn page: TextCssHandler) {
        FacadeScaleMedia.event(module: .dialog(page, dialog.title ?? dialog.message ?? "对话框"), source: .user, action: .hideDialog([:]))
    }
    
    public static func action(_ action: UIAlertAction, in dialog: UIAlertController, clickIn page: TextCssHandler) {
        FacadeScaleMedia.event(module: .dialog(page, dialog.title ?? dialog.message ?? "对话框"), source: .user, action: .click(action.title ?? action.description, [:]))
    }
    
    public static func click(item: String, in dialog: String, in page: TextCssHandler, extra: [String: Any] = [:]) {
        FacadeScaleMedia.event(module: .dialog(page, dialog), source: .user, action: .click(item, extra))
    }
    
    public static func click(item: String, in page: TextCssHandler, extra: [String: Any] = [:]) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .click(item, extra))
    }
    
    public static func clickPay(tag: String, in page: TextCssHandler, extra: [String: Any]) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .clickPay(extra), tag: tag)
    }
    
    public static func delete(item: String, in page: TextCssHandler, extra: [String: Any] = [:]) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .delete(item, extra))
    }
    
    public static func select(item: String, in page: TextCssHandler, extra: [String: Any] = [:]) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .select(item, extra))
    }
    
    public static func viewState(in page: TextCssHandler, changeTo state: [String: Any]) {
        FacadeScaleMedia.event(module: .page(page), source: .user, action: .state(state))
    }
    
    public static func event(module: StatsModule, item: String, source: CaptureSource, extra: [String: Any]) {
        FacadeScaleMedia.event(module: module, source: source, action: .event(item, extra))
    }
    
    static func eventExt(module: StatsModule, source: CaptureSource, name: String, parameters: [String: Any]) {
        AuditKit.shared.metrics(page: module.description, source: source.description, name: name, parameters: parameters)
    }
   
    public static func eventTag(module: StatsModule, tag: String, name: String, parameters: [String: Any] = [:]) {
        AuditKit.shared.metrics(page: module.description, source: CaptureSource.user.description, name: name, parameters: parameters, event_tag: tag)
        RemoteModule.log(module: .metrics, level: .info, content: "EventTag : tag = \(tag), name = \(name), parameters = \(parameters), module = \(module.description), source = \(CaptureSource.user.description)")
   
    }
    
    public static func coreEvent(category: String, tag: String, name: String, parameters: [String: Any] = [:]) {
        AuditKit.shared.metrics(page: category, source: CaptureSource.user.description, name: name, parameters: parameters, event_tag: tag, is_core_events: true)
        RemoteModule.log(module: .metrics, level: .info, content: "CoreEvent : tag = \(tag), name = \(name), parameters = \(parameters), category = \(category), source = \(CaptureSource.user.description)")
    }
    
    private static func event(module: StatsModule, source: CaptureSource, action: InteractionAction, tag: String? = nil) {
        switch (action) {
        case .state(let state):
            eventExt(module: module, source: source, name: "状态", parameters: state)
        case .showDialog(let extra):
            switch (module) {
            case .app:
                fallthrough
            case .page(_):
                eventExt(module: module, source: source, name: "弹出对话框", parameters: extra)
            case .dialog(let page, let name):
                var parameters = extra
                parameters["名称"] = name
                eventExt(module: .page(page), source: source, name: "弹出对话框", parameters: parameters)
            }
        case .hideDialog(let extra):
            switch (module) {
            case .app:
                fallthrough
            case .page(_):
                eventExt(module: module, source: source, name: "收起对话框", parameters: extra)
            case .dialog(let page, let name):
                var parameters = extra
                parameters["名称"] = name
                eventExt(module: .page(page), source: source, name: "收起对话框", parameters: parameters)
            }
        case .willEnter:
            break
        case .didEnter(let extra):
            if let tag = tag {
                eventTag(module: module, tag: tag, name: "展示", parameters: extra)
            } else {
                eventExt(module: module, source: source, name: "进入页面", parameters: [:])
            }
        case .leave(let extra):
            if let tag = tag {
                eventTag(module: module, tag: tag, name: "退出", parameters: extra)
            } else {
                eventExt(module: module, source: source, name: "离开页面", parameters: [:])
            }
            
        case .willRequest(let what, let extra):
            var parameters = extra
            parameters["名称"] = what
            eventExt(module: module, source: source, name: "请求内容", parameters: parameters)
        case .didRequest(let what, let success, let extra):
            var parameters = extra
            parameters["名称"] = what
            eventExt(module: module, source: source, name: success ? "请求成功" : "请求失败", parameters: parameters)
        case .willRestore:
            eventExt(module: module, source: source, name: action.description, parameters: [:])
        case .didRestore(let suc, let info):
            eventExt(module: module, source: source, name: suc ? "恢复购买成功" : "恢复购买失败", parameters: info)
        case .click(let what, let extra):
            eventExt(module: module, source: source, name: "点击: \(what)", parameters: extra)
        case .clickPay(let extra):
            if let tag = tag {
                eventTag(module: module, tag: tag, name: "购买点击", parameters: extra)
            }
        case .delete(let what, let extra):
            var parameters = extra
            parameters["目标"] = what
            eventExt(module: module, source: source, name: "删除", parameters: parameters)
        case .willPurchase(let what, let extra):
            if let tag = tag {
                eventTag(module: module, tag: tag, name: "开始付款", parameters: extra)
            } else {
                var parameters = extra
                parameters["商品id"] = what
                eventExt(module: module, source: source, name: "开始付款", parameters: parameters)
            }
        case .didPurchase(let what, let success, let extra):
            if let tag = tag {
                eventTag(module: module, tag: tag, name: success ? "付款成功" : "付款失败", parameters: extra)
            } else {
                var parameters = extra
                parameters["商品id"] = what
                eventExt(module: module, source: source, name: success ? "付款成功" : "付款失败", parameters: parameters)
            }
            
        case .willDeliveryProduct(let what, let transactionId, let extra):
            var parameters = extra
            parameters["商品id"] = what
            parameters["交易id"] = transactionId
            eventExt(module: module, source: source, name: "开始交付消耗型商品", parameters: parameters)
        case .didDeliveryProduct(let what, let transactionId, let success, let extra):
            var parameters = extra
            parameters["商品id"] = what
            parameters["交易id"] = transactionId
            eventExt(module: module, source: source, name: success ? "交付消耗型商品成功" : "交付消耗型商品失败", parameters: parameters)
        case .willVerify:
            eventExt(module: module, source: source, name: "开始校验", parameters: [:])
        case .didVerify(let success, let extra):
            eventExt(module: module, source: source, name: success ? "校验成功" : "校验失败", parameters: extra)
        case .select(let what, let extra):
            var parameters = extra
            parameters["目标"] = what
            eventExt(module: module, source: source, name: "选中", parameters: parameters)
        case .event(let what, let extra):
            eventExt(module: module, source: source, name: "事件: \(what)", parameters: extra)
        case .none:
            debugPrint("")
        }
        
        RemoteModule.log(module: .metrics, level: .info, content: "Event : module = \(module.description), source = \(source.description), action = \(action.description)")
    }
}

extension UIViewController: TextCssHandler {
    
    open override var description: String {
        return String(describing: type(of: self))
    }
}
