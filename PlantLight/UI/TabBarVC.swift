import UIKit

class TabBarVC: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        
        //HXKit.registerPush()
    }
    
    private func setupTabBar() {
        tabBar.backgroundColor = .white
        tabBar.tintColor = .appGreen
        tabBar.unselectedItemTintColor = UIColor(white: 0.6, alpha: 1.0)
        tabBar.isTranslucent = false
        
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "camera"), selectedImage: UIImage(systemName: "camera.fill"))
        
        let guideVC = GuideViewController()
        let guideNav = UINavigationController(rootViewController: guideVC)
        guideNav.tabBarItem = UITabBarItem(title: "Guide", image: UIImage(systemName: "book"), selectedImage: UIImage(systemName: "book.fill"))
        
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "settings_title".localStr, image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))
        
        viewControllers = [guideNav, homeNav,settingsNav]
        
        self.selectedIndex = 1
    }
}

