
import UIKit
import MessageUI

class EmailSender: NSObject, MFMailComposeViewControllerDelegate {
    
    static let shared = EmailSender()
    
    private override init() {
        super.init()
    }
    
    static func send(from viewController: UIViewController) {
        Self.shared.startContactUs(viewController: viewController)
    }
    
    private func startContactUs(viewController: UIViewController) {
        if !MFMailComposeViewController.canSendMail() {
            Tips.openContact()
            return
        }
        let emailSupport = AppBasic.config.email_support
        let appName = UIDevice.getAppName()
        let picker = MFMailComposeViewController()
        picker.mailComposeDelegate = self
        picker.setToRecipients([emailSupport.email])
        picker.setSubject(appName)
        
        var content = emailSupport.support_content
        if !content.isEmpty {
            if content.contains("#deviceId#") {
                content = content.replacingOccurrences(of: "#deviceId#", with: UIDevice.userId())
            }
            if content.contains("#appName#") {
                content = content.replacingOccurrences(of: "#appName#", with: appName)
            }
            if content.contains("#version#") {
                let version = "\(UIDevice.getLocalAppVersion())(\(UIDevice.getLocalAppBundleVersion()))"
                content = content.replacingOccurrences(of: "#version#", with: version)
            }
            picker.setMessageBody("\n\n\n\n\n\n\n\(content)", isHTML: false)
        }
        
        viewController.present(picker, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            break
        case .saved:
            Tips.toastOK("tips_contact_saved".localStr)
        case .sent:
            Tips.toastOK("tips_contact_ok".localStr)
        case .failed:
            Tips.toastFailed("tips_contact_failed".localStr)
        @unknown default:
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
