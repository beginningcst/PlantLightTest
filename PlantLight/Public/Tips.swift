
import UIKit
import StoreKit
import MBProgressHUD

struct Tips {
    
    static func openLink(_ url: String) {
        guard let url = URL(string: url) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    static func openContact() {
        let appName = UIDevice.getAppName().replacingOccurrences(of: " ", with: "")
        let mailtoURL = "mailto:\(AppBasic.config.email_support.email)?subject=\(appName)"
        openLink(mailtoURL)
    }
    
    
    static func openRate() {
        let urlStr = "itms-apps://itunes.apple.com/app/id\(AppBasic.config.version_info.appstoreId)?action=write-review"
        openLink(urlStr)
    }
    
    static func showRate(_ wh: Config.RateWhere) {
        if let configWhere = AppBasic.config.rate_popup_position {
            if !configWhere.contains(wh.rawValue) {
                return
            }
        }
        let allTimes = AppBasic.config.rate_popup_count
        let useCount = AppBasic.useRateTimes
        if useCount < allTimes {
            AppBasic.useRateTimes = useCount + 1
            let ratePercent = AppBasic.config.rate_popup_percent
            let randomNum = Int.rand(1, 100)
            if randomNum <= ratePercent {
                if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            }
        }
    }
}

extension Tips {
    
    static func sys1(_ vc: UIViewController, title: String? = "tips_title".localStr, content: String? = nil, ok: String = "tips_ok".localStr, action: (() -> Void)? = nil, isRepeat: Bool = false) {
        let alertController = UIAlertController(title: title, message: content, preferredStyle: .alert)
        let actionOk = UIAlertAction(title: ok, style: .destructive) { _ in
            if isRepeat {
                vc.present(alertController, animated: true)
            }
            action?()
        }
        alertController.addAction(actionOk)
        vc.present(alertController, animated: true, completion: nil)
    }
    
    static func sys2(_ vc: UIViewController, title: String? = "tips_title".localStr, content: String? = nil, ok: String = "tips_ok".localStr, cancel: String = "tips_cancel".localStr, action: (() -> Void)? = nil, cancelAction: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: content, preferredStyle: .alert)
        let actionOk = UIAlertAction(title: ok, style: .default) { _ in
            action?()
        }
        let actionCancel = UIAlertAction(title: cancel, style: .cancel) { _ in
            cancelAction?()
        }
        alertController.addAction(actionOk)
        alertController.addAction(actionCancel)
        vc.present(alertController, animated: true, completion: nil)
    }
    
    static func sysN(_ vc: UIViewController, title: String?, buttons: [String], action: @escaping (Int) -> Void) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        for (index, buttonTitle) in buttons.enumerated() {
            let actionButton = UIAlertAction(title: buttonTitle, style: .default) { _ in
                action(index)
            }
            alertController.addAction(actionButton)
        }
        
        let cancelAction = UIAlertAction(title: "tips_cancel".localStr, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        vc.present(alertController, animated: true, completion: nil)
    }
}

extension Tips {
    
    private static var window: UIWindow? {
        UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    static func wait(canTouch: Bool = false, desc: String? = nil) {
        guard let window = window else { return }
        dismiss()

        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = .indeterminate
        hud.label.text = desc
        hud.removeFromSuperViewOnHide = true
        hud.bezelView.style = .solidColor
        hud.bezelView.color = UIColor(white: 0, alpha: 0.8)
        hud.contentColor = .white
        hud.isUserInteractionEnabled = !canTouch
    }

    static func waitPercent(_ progress: Float, desc: String? = nil) {
        guard let window = window else { return }
        dismiss()

        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = .annularDeterminate
        hud.progress = progress
        hud.label.text = desc ?? "\(Int(progress * 100))%"
        hud.removeFromSuperViewOnHide = true
        hud.bezelView.style = .solidColor
        hud.bezelView.color = UIColor(white: 0, alpha: 0.8)
        hud.contentColor = .white
        hud.isUserInteractionEnabled = false
    }

    static func dismiss() {
        guard let window = window else { return }
        MBProgressHUD.hide(for: window, animated: true)
    }

    static func toastOK(_ desc: String) {
        showToast(desc, customView: UIImageView(image: UIImage(systemName: "checkmark.circle.fill")))
    }

    static func toastFailed(_ desc: String) {
        showToast(desc, customView: UIImageView(image: UIImage(systemName: "xmark.circle.fill")))
    }

    private static func showToast(_ desc: String, customView: UIView?) {
        guard let window = window else { return }
        dismiss()

        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = .customView
        if let customView = customView {
            (customView as? UIImageView)?.tintColor = .white
            hud.customView = customView
        }
        hud.label.text = desc
        hud.label.numberOfLines = 0
        hud.bezelView.style = .solidColor
        hud.bezelView.color = UIColor(white: 0, alpha: 0.8)
        hud.contentColor = .white
        hud.isUserInteractionEnabled = false
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 1.5)
    }
}
