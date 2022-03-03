
import Foundation
import UIKit
import SnapKit
import MBProgressHUD
import NVActivityIndicatorView

extension UIView {

    static func flash(_ view:UIView,completion: @escaping () -> Void){
        UIView.animate(withDuration: 0.3, animations: {
            view.layer.opacity = 0.7
            view.layer.opacity = 1.0
            completion()
        })
    }
    
    var safeArea: ConstraintBasicAttributesDSL {
        #if swift(>=3.2)
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.snp
        }
        return self.snp
        #else
        return self.snp
        #endif
    }
    
    func progressHUD(show: Bool, animated: Bool = true) {
        if show {
            /*let container = UIView(frame: self.bounds)
            let hub = NVActivityIndicatorView(frame: CGRect(origin: .zero, size: NVActivityIndicatorView.DEFAULT_BLOCKER_SIZE),
                                              type: .ballSpinFadeLoader,
                                              color: .white,
                                              padding: 0)
             container.addSubview(hub)
             self.addSubview(container)
             container.backgroundColor = UIColor(white: 0, alpha: 0.4)
             hub.center = container.center
             hub.startAnimating()*/
            let hub = MBProgressHUD.showAdded(to: self, animated: animated)
            hub.backgroundColor = UIColor(white: 0, alpha: 0.3)
        } else {
            /*self.subviews.filter{ (subview) -> Bool in
                subview.subviews.filter{ $0 is NVActivityIndicatorView }.count > 0
                }.forEach { (subview) in
                    subview.removeFromSuperview()
            }*/
            MBProgressHUD.hide(for: self, animated: animated)
        }
    }
}

enum BorderPosition {
    case top
    case left
    case right
    case bottom
}

extension UIView {
    /// 特定の場所にborderをつける
    ///
    /// - Parameters:
    ///   - width: 線の幅
    ///   - color: 線の色
    ///   - position: 上下左右どこにborderをつけるか
    func addBorder(width: CGFloat, color: UIColor, position: BorderPosition) {
        
        let border = CALayer()
        
        switch position {
        case .top:
            border.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: width)
            border.backgroundColor = color.cgColor
            self.layer.addSublayer(border)
        case .left:
            border.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.height)
            border.backgroundColor = color.cgColor
            self.layer.addSublayer(border)
        case .right:
            border.frame = CGRect(x: self.frame.width - width, y: 0, width: width, height: self.frame.height)
            border.backgroundColor = color.cgColor
            self.layer.addSublayer(border)
        case .bottom:
            border.frame = CGRect(x: 0, y: self.frame.height - width, width: self.frame.width, height: width)
            border.backgroundColor = color.cgColor
            self.layer.addSublayer(border)
        }
    }
}

extension UIView {
    @objc func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {}
}
