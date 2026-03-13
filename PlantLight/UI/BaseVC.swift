
import UIKit
import MessageUI
import AVFoundation
import LocalAuthentication

extension UIViewController {
    
    enum WebPage {
        case terms
        case policy
        case page(_ name: String, _ url: String)
    }
    
    var barStyle: UIBarStyle? {
        get {
            self.navigationController?.barStyle
        }
        set {
            self.navigationController?.barStyle = newValue
        }
    }
    
    func pushVCWithPopSelf(newVC: UIViewController) {
        self.navigationController?.pushViewController(newVC, animated: true)
        if var viewControllers = self.navigationController?.viewControllers {
            viewControllers.removeAll { $0 == self }
            self.navigationController?.setViewControllers(viewControllers, animated: true)
        }
    }
    
    func showShareApp() {
        let url = AppBasic.config.version_info.url
        let activityItems: [Any] = ["\("tips_share_text".localStr) \(url)", URL(string: url)!]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.permittedArrowDirections = .up
        }
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            if completed {
                Tips.toastOK("tips_share_ok".localStr)
            } else {
                Tips.toastFailed("tips_share_failed".localStr)
            }
        }
        self.present(activityVC, animated: true, completion: nil)
    }
    
    func showWebPage(_ page: WebPage) {
        var curURL: String!
        switch page {
        case .terms:
            curURL = "\(Constant.termURL)?version=\(UIDevice.getLocalAppBundleVersion())&equipment_id=\(UIDevice.userId())&package=\(Constant.bundleId)&lan=\(UIDevice.getLocaleLanguage())"
        case .policy:
            curURL = "\(Constant.policyURL)?version=\(UIDevice.getLocalAppBundleVersion())&equipment_id=\(UIDevice.userId())&package=\(Constant.bundleId)&lan=\(UIDevice.getLocaleLanguage())"
        case .page(_, let url):
            curURL = url
        }
        if let url = URL(string: curURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func showVerIfNeed() {
        let ver = AppBasic.config.version_info
        let buildVer = Int(UIDevice.getLocalAppBundleVersion()) ?? 0
        if buildVer < ver.code {
            let title = "\("tips_update_title".localStr) \(ver.name)"
            if ver.isForce == 1 {
                Tips.sys1(self,title: title, content: ver.text, ok: "tips_update_action".localStr, action: {
                    Tips.openLink(ver.url)
                }, isRepeat: true)
            }else {
                Tips.sys2(self,title: title, content: ver.text, ok: "tips_update_action".localStr, action: {
                    Tips.openLink(ver.url)
                })
            }
        }
    }
}

extension UIViewController {
    
    static func getCurrentViewController() -> UIViewController? {
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            return getVisibleViewController(from: rootVC)
        }
        return nil
    }
    
    private static func getVisibleViewController(from rootViewController: UIViewController) -> UIViewController {
        if let navigationController = rootViewController as? UINavigationController {
            return getVisibleViewController(from: navigationController.visibleViewController!)
        }
        if let tabBarController = rootViewController as? UITabBarController {
            return getVisibleViewController(from: tabBarController.selectedViewController!)
        }
        if let presentedVC = rootViewController.presentedViewController {
            return getVisibleViewController(from: presentedVC)
        }
        return rootViewController
    }
}

class BaseVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
