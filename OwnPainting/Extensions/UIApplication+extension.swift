import Foundation
import UIKit
extension UIApplication {
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
    
    var topViewController: UIViewController? {
        guard var topViewController = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }
    
    var topNavigationController: UINavigationController? {
        return topViewController as? UINavigationController
    }
}
