import Foundation
import UIKit


extension UIColor {
    
    static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    struct MyTheme {
        // ナビゲーションバーのテキストカラー
        static var textColorOfNavigationBar: UIColor {
            return UIColor.Custom.white
        }


        // タップできない場合の入力項目のテキストカラー
        static var invalidTextColor: UIColor {
            return UIColor.gray
        }

        static var invalidBackgroundColorOfTableHeaderView: UIColor {
            return UIColor.hexStringToUIColor(hex: "D9D9D9")
        }

        static var backgroundColorOfTableHeaderView: UIColor {
            return UIColor.Custom.lightGreen

        }

        // ナビゲーションバーの背景色
        static var backgroundColorOfNavigationBar: UIColor {
            return UIColor.Custom.darkGreen
        }

        // 会社名、作業所名を表示するラベルのテキストカラー
        static var textColorOfInformation: UIColor {
            return UIColor.Custom.white
        }
        // 会社名、作業所名を表示するラベルの背景色
        static var backgroundColorOfInformation: UIColor {
            return UIColor.lightGray
        }
   

        // 作業所名、会社名を表示するラベルのテキストカラー
        static var textColorOfInformationLabel: UIColor {
            return UIColor.Custom.white
        }
        // セルの背景色
        static var backgroundColorOfTableViewCell: UIColor {
            return UIColor.Custom.white
        }
        // セルのテキストカラー
        static var textColorOfTableViewCell: UIColor {
            return UIColor.Custom.green
        }
        
        // セルのテキストカラーNotMatch
        static var textColorNotMatchOfTableViewCell: UIColor {
            return UIColor.hexStringToUIColor(hex: "CBEACF")
        }
        
        // セルのテキストカラーNotMatch
        static var textColorDescriptionOfTableViewCell: UIColor {
            return UIColor.Custom.darkGray
        }
        
        // セルのテキストカラーNotMatch
        static var textColorDescriptionNotMatchOfTableViewCell: UIColor {
            return UIColor.Custom.lightGray
        }
        // タブエリアの背景色
        static var backgroundOfTabArea: UIColor {
            return UIColor.Custom.black
        }
        // タブボタンの背景色
        static var backgroundColorOfTabButton: UIColor {
            return UIColor.Custom.darkGreen
        }
        // タブエリアのテキストカラー
        static var textColorOfTabButton: UIColor {
            return UIColor.Custom.white
        }
        // タブボタン選択時の背景色
        static var backgroundColorOfTabButtonDidSelect: UIColor {
            return UIColor.Custom.white
        }
        // タブボタン選択時のテキストカラー
        static var textColorOfTabButtonDidSelect: UIColor {
            return UIColor.Custom.darkGreen
        }
        
        // キーボード上部に表示するツールバーの背景色
        static var backgroundColorOfToolbarOnKeyboard: UIColor {
            return UIColor.Custom.lightGray
        }
        // キーボード上部に表示するツールバーのテキストカラー
        static var textColorOfToolbarOnKeyboard: UIColor {
            return UIColor.Custom.black
        }
        // 画面下部に表示するツールバーの背景色
        static var backgroundColorOfBottomToolbar: UIColor {
            return UIColor.Custom.darkGreen
        }
        // 画面下部に表示するツールバーのテキストカラー
        static var textColorOfBottomToolbar: UIColor {
            return UIColor.Custom.white
        }
        
        // ボタンの背景色
        static var backgroundColorOfButton: UIColor {
            return  UIColor.Custom.darkGreen
        }
        // ボタンのテキストカラー
        static var textColorOfButton: UIColor {
            return  UIColor.Custom.white
        }
        
        // ボタン選択時の背景色
        static var backgroundColorOfButtonDidSelect: UIColor {
            return  UIColor.Custom.darkGreen
        }
        // ボタン選択時のテキストカラー
        static var textColorOfButtonDidSelect: UIColor {
            return  UIColor.Custom.white
        }

        static var backgroundColorOfInputTextField: UIColor {
            return UIColor.Custom.white
        }
        
        static var backgroundColorOfInputTextFieldDisabled: UIColor {
            return self.backgroundColorOfInputTextField
        }
        
        static var backgroundColorOfInputCell: UIColor {
            return UIColor.Custom.white
        }
        
        static var backgroundColorOfInputCellDisabled: UIColor {
            return UIColor.Custom.white
        }
        
        static var underlineColorOfInputCell: UIColor {
            return UIColor.Custom.black
        }
        
        static var underlineColorOfInputCellDisabled: UIColor {
            return self.underlineColorOfInputCell
        }
        
        // ReportTableViewの背景色
        static var backgroundColorOfReportTableView: UIColor {
            return UIColor.white
        }
        
        static var backgroundColorOfReportTableViewDisabled: UIColor {
            return UIColor.white
        }
    }
    
    struct Custom {
        
       
        
        static var white: UIColor {
            return UIColor.white
        }
        static var red: UIColor {
            return UIColor.red
        }
        static var black: UIColor {
            return UIColor.hexStringToUIColor(hex: "#334455")
        }
        static var orange: UIColor {
            return UIColor.orange
        }
        static var gray:UIColor {
             return UIColor(red: 246 / 255, green: 246 / 255, blue: 246 / 255, alpha: 1)
        }
        static var yellow: UIColor {
            return UIColor(red: 250 / 255, green: 180 / 255, blue: 32 / 255, alpha: 1)
        }
        static var blue:UIColor {
            return UIColor.blue
        }
        static var green: UIColor {
            return UIColor.hexStringToUIColor(hex: "#32AC41")
        }
        static var darkGreen:UIColor {
            return UIColor.hexStringToUIColor(hex: "#1A6538")
        }
        static var lightGreen:UIColor {
            return UIColor.hexStringToUIColor(hex: "#BCF3BC")
        }
        static var lightGray:UIColor {
            return UIColor.hexStringToUIColor(hex: "#C7D2D2")
        }
        static var darkGray:UIColor {
            return UIColor.darkGray
        }
        static var selected: UIColor {
            return UIColor.hexStringToUIColor(hex: "#F8E81C")
        }


    }
}



