
import UIKit

extension UINavigationController {
    
    func setRootVC(_ vc: UIViewController) {
        self.setViewControllers([vc], animated: false)
    }
}

class AppRootVC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !AppBasic.isAgreeShow {
            setRootVC(AgreeViewController())
        }else {
            setRootVC(TabBarVC())
        }
    }
}
