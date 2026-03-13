import UIKit

extension UIColor {
    static let appGreen = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
    static let appOrange = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    static let appBackground = UIColor(red: 245/255, green: 250/255, blue: 245/255, alpha: 1.0)
    static let appTextPrimary = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
    static let appTextSecondary = UIColor(red: 117/255, green: 117/255, blue: 117/255, alpha: 1.0)
}

extension Int {
    static func rand(_ from: Int, _ to: Int) -> Int {
        return (from + (Int(arc4random()) % (to-from+1)))
    }
}

extension String {
    func toDictionary() -> [String: Any]?  {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        do {
            if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return dictionary
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func toArray() -> [Any]?  {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        
        do {
            if let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                return array
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

extension Dictionary {
    func toJSONString() -> String? {
        guard JSONSerialization.isValidJSONObject(self) else {
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

extension Array {
    
    func toJSONString() -> String? {
        guard JSONSerialization.isValidJSONObject(self) else {
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        var hexString: String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        if hexString.count != 6 {
            self.init(red: 0, green: 0, blue: 0, alpha: alpha)
            return
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
}
extension String {
    func localStr(_ replace: String, tag: String = "--") -> String {
        let str = self.localStr
        if str.contains(tag) {
            return str.replacingOccurrences(of: tag, with: replace)
        }
        return str
    }
    func localStr(_ replace1: String, _ replace2: String, tag1: String = "--", tag2: String = "##") -> String {
        var str = self.localStr
        if str.contains(tag1) {
            str = str.replacingOccurrences(of: tag1, with: replace1)
        }
        if str.contains(tag2) {
            return str.replacingOccurrences(of: tag2, with: replace2)
        }
        return str
    }
}


@IBDesignable
class BorderButton: UIButton {
    @IBInspectable var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let color = self.layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            self.layer.borderColor = newValue?.cgColor
        }
    }
}

extension UILabel {
    
    func configureAttrText(_ title: String, font: UIFont? = nil) {
        guard title.contains("{") && title.contains("}") else {
            self.text = title
            return
        }
        let newStr = title.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
        let attributedString = NSMutableAttributedString(
            string: newStr,
            attributes: [
                .font: self.font ?? UIFont.systemFont(ofSize: 18.fitX),
                .foregroundColor: textColor ?? .black
            ]
        )
        let regexPattern = "\\{[^\\}]+\\}"
        if let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: title, options: [], range: NSRange(location: 0, length: title.utf16.count))
            for match in matches {
                if let range = Range(match.range, in: title) {
                    let matchedText = title[range]
                    if let innerRange = matchedText.range(of: "(?<=\\{).*(?=\\})", options: .regularExpression) {
                        let innerText = matchedText[innerRange]
                        if let targetRange = newStr.range(of: innerText) {
                            let nsRange = NSRange(targetRange, in: newStr)
                            attributedString.addAttribute(.foregroundColor, value: UIColor.appOrange, range: nsRange)
                            if let font {
                                attributedString.addAttribute(.font, value: font, range: nsRange)
                            }
                        }
                    }
                }
            }
        }
        self.attributedText = attributedString
    }
}
