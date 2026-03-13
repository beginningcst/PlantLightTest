
import UIKit

class AgreeViewController: BaseVC {
    
    @IBOutlet weak var shadowView: UIView!
    
    var gradientLayer: CAGradientLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        Event.add(.feature_agreement_show)
        
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.init(red: 0, green: 0, blue: 0, alpha: 0).cgColor,
                                UIColor.init(red: 0, green: 0, blue: 0, alpha: 1).cgColor]
        shadowView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = shadowView.bounds
    }
    
    @IBAction func agreeBtnClick(_ sender: Any) {
        Event.add(.feature_agreement_agree_click)
        AppBasic.isAgreeShow = true
        pushVCWithPopSelf(newVC: TabBarVC())
    }
    
    @IBAction func termsBtnClick(_ sender: Any) {
        Event.add(.feature_agreement_terms_click)
        showWebPage(.terms)
    }

}
