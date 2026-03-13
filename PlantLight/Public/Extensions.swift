import UIKit

extension String {
    var localStr: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension UIColor {
    static let appGreen = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
    static let appOrange = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    static let appBackground = UIColor(red: 245/255, green: 250/255, blue: 245/255, alpha: 1.0)
    static let appTextPrimary = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
    static let appTextSecondary = UIColor(red: 117/255, green: 117/255, blue: 117/255, alpha: 1.0)
}
