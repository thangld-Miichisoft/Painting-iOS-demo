import UIKit
import Foundation


extension UIFont {
    
    struct Custom {
        
        static func navigationTitle() -> UIFont {
            return self.text()
        }
   
        static func h1() -> UIFont {
            return UIFont.boldSystemFont(ofSize: 17)
        }
        
   
        static func h2() -> UIFont  {
            return UIFont.systemFont(ofSize: 12)
        }
        
        
        static func text() -> UIFont {
            return UIFont.systemFont(ofSize: 10)
        }
        
        

    }

}
