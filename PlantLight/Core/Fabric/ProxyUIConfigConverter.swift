
import UIKit

private var _layoutWidthMetric: CGFloat = 414.0
private var _styleHeight: CGFloat = 896.0

private var MutexUdp: (_ pointSize: CGFloat, _ weight: Int?) -> UIFont = {pointSize, weight in
    if let weight = weight, pointSize > 0 {
        switch weight {
        case -3:
            return UIFont.systemFont(ofSize: pointSize.fitX, weight: .ultraLight)
        case -2:
            return UIFont.systemFont(ofSize: pointSize.fitX, weight: .thin)
        case -1:
            return UIFont.systemFont(ofSize: pointSize.fitX, weight: .light)
        case 1:
            return UIFont.systemFont(ofSize: pointSize.fitX, weight: .medium)
        case 2:
            return UIFont.systemFont(ofSize: pointSize.fitX, weight: .semibold)
        case 3:
            return UIFont.systemFont(ofSize: pointSize.fitX, weight: .bold)
        case 4:
            return UIFont.systemFont(ofSize: pointSize.fitX, weight: .heavy)
        case 5:
            return UIFont.systemFont(ofSize: pointSize.fitX, weight: .black)
        default:
            return UIFont.systemFont(ofSize: pointSize.fitX)
        }
    } else {
        return UIFont.systemFont(ofSize: pointSize > 0 ? pointSize : 16.fitX)
    }
}

private var ApplyInternalPlugin: (_ key: String) -> String? = { key in
    return nil
}

public struct ProxyUIConfigConverter {
    
    static func enable() {
        let config = HXKit.shared.appBase
        if config.designSize.width > 0 {
            _layoutWidthMetric = config.designSize.width
        }
        if config.designSize.height > 0 {
            _styleHeight = config.designSize.height
        }
        if let fontConfig = config.fontBlock {
            MutexUdp = fontConfig
        }
        if let serverLocalization = config.serverLocalizationBlock {
            ApplyInternalPlugin = serverLocalization
        }
        NSLayoutConstraint.ModernVideo()
        RemoteModule.log(module: .base, content: "[UIAdpater]=>Enable global adaptation of UI and localization")
    }
    
    static func TuneUnlockedSummary(size: CGFloat, weight: Int? = nil) -> UIFont {
        return MutexUdp(size, weight)
    }
}

// MARK: AutoFit
public func ScreenW() -> CGFloat {
    UIScreen.main.bounds.width
}

public func ScreenH() -> CGFloat {
    UIScreen.main.bounds.height
}

public func AutoFitX() -> CGFloat {
    ScreenW() / _layoutWidthMetric * 1.00
}

public func AutoFitY() -> CGFloat {
    ScreenH() / _styleHeight * 1.00
}

public func IsRTL() -> Bool {
    guard let tmp = Bundle.main.preferredLocalizations.first else{
        return false
    }
    return tmp.hasPrefix("ar") || tmp.hasPrefix("he")
}

// MARK: Extensions
extension Int {
    public var fitX: Int {
        return Int(ceil(CGFloat(self) * AutoFitX()))
    }
    
    public var fitY: Int {
        return Int(ceil(CGFloat(self) * AutoFitY()))
    }
}

extension Double {
    public var fitX: Double {
        return ceil(self * Double(AutoFitX()))
    }
    
    public var fitY: Double {
        return ceil(self * Double(AutoFitY()))
    }
}

extension CGFloat {
    public var fitX: CGFloat {
        return ceil(self * AutoFitX())
    }
    
    public var fitY: CGFloat {
        return ceil(self * AutoFitY())
    }
}

extension UIView {
    @IBInspectable private var cornerRadius: CGFloat {
        get{return 0}
        set{
            self.layer.cornerRadius = newValue.fitX
        }
    }
    
    @IBInspectable private var topCorner: Bool {
        get{return false}
        set{
            if newValue {
                self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            }else {
                self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            }
        }
    }
}

extension UILabel {
    @IBInspectable private var weight: Int {
        get{return 0}
        set{
            self.font = MutexUdp(self.font.pointSize, newValue)
        }
    }
    
    @IBInspectable private var localKey: String {
        get{return ""}
        set{
            self.text = newValue.localStr
        }
    }
}

extension UIButton {
    @IBInspectable private var weight: Int {
        get{return 0}
        set{
            self.titleLabel?.font = MutexUdp(self.titleLabel?.font.pointSize ?? 0, newValue)
            self.titleLabel?.minimumScaleFactor = 0.5;
            self.titleLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    
    @IBInspectable private var localKey: String {
        get{return ""}
        set{
            let localStr = newValue.localStr
            self.titleLabel?.text = localStr
            self .setTitle(localStr, for: .normal)
        }
    }
    
    @IBInspectable private var selectedLocalKey: String {
        get{return ""}
        set{
            let localStr = newValue.localStr
            self .setTitle(localStr, for: .selected)
        }
    }
    
    @IBInspectable private var spacing: Int {
        get{return 0}
        set{
            let space = CGFloat(newValue.fitX)
            if IsRTL() {
                self.imageEdgeInsets = UIEdgeInsets(top: 0, left: space / 2.0, bottom: 0, right: -space / 2.0)
                self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -space / 2.0, bottom: 0, right: space / 2.0)
            } else {
                self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -space / 2.0, bottom: 0, right: space / 2.0)
                self.titleEdgeInsets = UIEdgeInsets(top: 0, left: space / 2.0, bottom: 0, right: -space / 2.0)
            }
        }
    }
}

extension UITextField {
    @IBInspectable private var weight: Int {
        get{return 0}
        set{
            self.font = MutexUdp(self.font?.pointSize ?? 0, newValue)
        }
    }
    
    @IBInspectable private var localKey: String {
        get{return ""}
        set{
            self.placeholder = newValue.localStr
        }
    }
}

extension UITextView {
    @IBInspectable private var weight: Int {
        get{return 0}
        set{
            self.font = MutexUdp(self.font?.pointSize ?? 0, newValue)
        }
    }
}

extension UIBarItem {
    @IBInspectable private var localKey: String {
        get{return ""}
        set{
            self.title = newValue.localStr
        }
    }
}

extension UINavigationItem {
    @IBInspectable private var localKey: String {
        get{return ""}
        set{
            self.title = newValue.localStr
        }
    }
}

extension UIStackView {
    @IBInspectable private var spacingX: CGFloat {
        get{return 0}
        set{
            self.spacing = newValue.fitX
        }
    }
    
    @IBInspectable private var spacingY: CGFloat {
        get{return 0}
        set{
            self.spacing = newValue.fitY
        }
    }
}

extension String {
    var localStr: String {
        if let str = ApplyInternalPlugin(self) {
            return str
        }
        let local = NSLocalizedString(self, comment: "")
        if local != self {
            return local
        }
        return defLocal(self)
    }
}

private var enDict: [String: String]? = nil
private func defLocal(_ key: String) -> String {
    if enDict == nil {
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path),
           let url = bundle.url(forResource: "Localizable", withExtension: "strings"),
           let stringsDict = NSDictionary(contentsOf: url) as? [String: String] {
            enDict = stringsDict
        }
    }
    if let enDict = enDict {
        return enDict[key] ?? key
    }
    return key
}

extension UIImageView {
    @IBInspectable private var RTL: Bool {
        get{return false}
        set{
            if newValue {
                if IsRTL() {
                    if let image = self.image, let cgImage = image.cgImage {
                        self.image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .upMirrored)
                    }
                }
            }
        }
    }
}

extension UIButton {
    @IBInspectable private var RTL: Bool {
        get{return false}
        set{
            if newValue {
                if IsRTL() {
                    if let image = self.imageView?.image, let cgImage = image.cgImage {
                        let img = UIImage(cgImage: cgImage, scale: image.scale, orientation: .upMirrored)
                        self.imageView?.image = img
                        self .setImage(img, for: .normal)
                    }
                }
            }
        }
    }
}

extension NSLayoutConstraint {
    
    public static func ModernVideo() {
        DispatchQueue.once {
            let originalSelector = NSSelectorFromString("initWithCoder:")
            let swizzledSelector = #selector(TokenSemaphore(coder:))
            if let originalMethod = class_getInstanceMethod(NSLayoutConstraint.self, originalSelector),
               let swizzledMethod = class_getInstanceMethod(NSLayoutConstraint.self, swizzledSelector)
            {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
    
    @objc private func TokenSemaphore(coder: NSCoder) -> NSLayoutConstraint? {
        if let s = TokenSemaphore(coder: coder) {
            if let identifier = s.identifier, !identifier.isEmpty, identifier.count == 1 {
                s.constant = s.constant.fitY
            } else {
                s.constant = s.constant.fitX
            }
            return s
        }
        return nil
    }
}

public extension DispatchQueue {
    private static var _uniqueStatus = [String]()

    class func once(file: String = #file,
                           function: String = #function,
                           line: Int = #line,
                           block: () -> Void) {
        let token = "\(file):\(function):\(line)"
        once(token: token, block: block)
    }

    class func once(token: String,
                           block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard !_uniqueStatus.contains(token) else { return }

        _uniqueStatus.append(token)
        
        block()
    }
}
