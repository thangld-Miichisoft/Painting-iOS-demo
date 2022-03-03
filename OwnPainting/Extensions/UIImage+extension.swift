import UIKit
extension UIImage {
    
    func resizeImageToIconSize() -> UIImage {
        let iconSize = CGSize(width: 27, height: 27)
        return self.resizeImage(targetSize: iconSize)
    }

    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func toBase64ImagePng()->String?{
        let imageData:Data = self.pngData()!
        return  imageData.base64EncodedString(options: .init(rawValue: 0))
    }
    
    class func genImageWhite(size: CGSize)-> UIImage{
        return UIColor.white.image(size)
    }
    
    class func loadSample_Image()->UIImage{
        if let imageOrigin = UIImage(named: "drawing_image") {
            return genImageWhite(size: imageOrigin.size)
        }
        return genImageWhite(size: CGSize(width: 2088, height: 261))
        
    }
    
}
