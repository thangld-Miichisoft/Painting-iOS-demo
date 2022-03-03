//
//  DateUtil.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//


import UIKit

enum PhotoructionTimeZone: String {
    case GMT = "GMT"
    case UTC = "UTC"
    case JST = "JST"
    case Locale = "locale"
}

enum PhotoructionDateFormat: String {
    case Date_Hyphen = "yyyy-MM-dd"
    case DateTime_Hyphen = "yyyy-MM-dd HH:mm:ss"
    case DateTimeWithMilliSec_NonSeparate = "yyyyMMddHHmmssSSSSS"
    case DateTime_Colon = "yyyy:MM:dd HH:mm:ss"
    case DateTime_Slash = "yyyy/MM/dd HH:mm"
    case DateTime_NonSeparate = "yyyyMMddHHmmss"
    case DateTime_Kanji = "yyyy年MM月dd日HH時mm分ss秒"
    case Date_UnderScore = "yyyy_MM_dd"
    case Date_Slash_NonZero = "yyyy/M/d"
    case Date_Slash = "yyyy/MM/dd"
    case DateTime_Kanji_Colon = "yyyy年MM月dd日 HH:mm:ss"
}

final class DateUtil: NSObject {
    
    func date(string: String, format: PhotoructionDateFormat) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        dateFormatter.locale = Locale(identifier: "ja_JP")
        return dateFormatter.date(from: string)
    }
    
    func date(string: String, format: PhotoructionDateFormat, timeZone: PhotoructionTimeZone) -> Date? {
        let dateFormatter = makeDateFormatter(format, timeZone: timeZone)
        return dateFormatter.date(from: string)
    }
    
    func string(date: Date, format: PhotoructionDateFormat) -> String {
        let formatter = makeDateFormatter(format, timeZone: .JST)
        return formatter.string(from: date)
    }
    
    func string(date: Date, format: PhotoructionDateFormat, timeZone: PhotoructionTimeZone) -> String {
        let formatter = makeDateFormatter(format, timeZone: timeZone)
        return formatter.string(from: date)
    }
    
    func string(date: Date) -> String {
        let formatter = makeDateFormatter(.DateTime_Colon, timeZone: .JST)
        return formatter.string(from: date)
    }
    
    func stringLocale(date: Date, format: PhotoructionDateFormat) -> String {
        let formatter = makeDateFormatter(format, timeZone: .Locale)
        return formatter.string(from: date)
    }
    
    func jstDate(format: String) -> String {
        let formatter = dateFormatterMaker(format, timeZone: TimeZone(identifier: PhotoructionTimeZone.JST.rawValue)!)
        let date = Date()
        return formatter.string(from: date)
    }
    
    func getJSTDateString(_ format: String) -> (dateTime: String, millSec: String) {
        let formatter = dateFormatterMaker("\(PhotoructionDateFormat.DateTime_Colon.rawValue)|SSS", timeZone: TimeZone(identifier: PhotoructionTimeZone.JST.rawValue)!)
        let date = Date()
        let result = formatter.string(from: date)
        let arr = result.components(separatedBy: "|")
        let dateTime = arr[0]
        let millSec = arr[1]
        return (dateTime, millSec)
    }
    
    func getJSTDateString(_ format: PhotoructionDateFormat) -> String {
        return getDateString(format, timeZone: PhotoructionTimeZone.JST)
    }
    
    func getDateString(_ format: PhotoructionDateFormat, timeZone: PhotoructionTimeZone) -> String {
        let formatter: DateFormatter = makeDateFormatter(format, timeZone: timeZone)
        let date: Date = Date()
        let result: String = formatter.string(from: date)
        return result
    }
    
    func convertTimeZone(_ fromString: String, fromFormat: PhotoructionDateFormat, fromTimeZone: PhotoructionTimeZone, toString: String, toFormat: PhotoructionDateFormat, toTimeZone: PhotoructionTimeZone) -> String? {
        let fromFormatter: DateFormatter = makeDateFormatter(fromFormat, timeZone: fromTimeZone)
        let toFormatter: DateFormatter = makeDateFormatter(toFormat, timeZone: toTimeZone)
        
        if let date: Date = fromFormatter.date(from: fromString) {
            let result: String = toFormatter.string(from: date)
            return result
        }
        return nil
    }
    
   
    
    func generatePrettyDateFormat(date: String, fromFormat: PhotoructionDateFormat) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = fromFormat.rawValue
        if Locale.preferredLanguages.first?.contains("ja") == true {
            dateFormatter.locale = Locale(identifier: "ja_JP")
        } else {
            dateFormatter.locale = Locale(identifier: "en_US")
        }
        dateFormatter.amSymbol = "am"
        dateFormatter.pmSymbol = "pm"
        
        let calendar = Calendar(identifier: .gregorian)
        
        guard let date = dateFormatter.date(from: date) else {
            return nil
        }
        var now = Date()
        var convertedDate = date
        
        // 時間系を初期化
        now = calendar.startOfDay(for: now)
        convertedDate = calendar.startOfDay(for: convertedDate)
        
        // 差分計測
        if let delta = calendar.dateComponents([.day], from: convertedDate, to: now).day {
            switch delta {
            case 0:
                dateFormatter.dateFormat = "h:mma"
                return ""
            case 1:
                dateFormatter.dateFormat = "h:mma"
                return ""
            case 2...7:
                dateFormatter.dateFormat = "h:mma"
                return ""
            default:
                return ""
//                dateFormatter.dateFormat = R.string.localizable.date1()
//                return dateFormatter.string(from: date)
            }
        } else {
//            dateFormatter.dateFormat = R.string.localizable.date1()
//            return dateFormatter.string(from: date)
            return ""
        }
    }
    
    func generateDateStringForNavigationBarWith(_ convertingDate: String) -> NSMutableAttributedString? {
        var attributedText: NSMutableAttributedString?
        var attributedTexts: [String]?
        if let prettryFormat = generatePrettyDateFormat(date: convertingDate, fromFormat: .DateTime_Hyphen) {
            attributedTexts = prettryFormat.components(separatedBy: "|")
        } else {
            attributedTexts = convertingDate.components(separatedBy: " ")
        }
        if attributedTexts?.count == 2 {
            attributedText = NSMutableAttributedString(string: attributedTexts![0] + "\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
            attributedText?.append(NSMutableAttributedString(string: attributedTexts![1], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]))
        }
        return attributedText
    }
    
    func validateDate(start: String, end: String, format: String = "yyyy-MM-dd HH:mm:ss") -> Bool {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = format
        
        if let start = dateformatter.date(from: start), let end = dateformatter.date(from: end) {
            return end > start
        }
        
        return false
    }
    
    func convert(dateString: String, fromFormat: PhotoructionDateFormat, toFormat: PhotoructionDateFormat) -> String? {
        let from = makeJSTDateFormatter(fromFormat)
        let to = makeJSTDateFormatter(toFormat)
        
        guard let date = from.date(from: dateString) else {
            return nil
        }
        return to.string(from: date)
    }
    
    func deltaMonth(from: Date, to: Date) -> Int? {
        let calendar = Calendar(identifier: .gregorian)
        if let deltaMonth = calendar.dateComponents([.month], from: from, to: to).month,
           let fromDay = calendar.dateComponents([.day], from: from).day,
           let toDay = calendar.dateComponents([.day], from: to).day {
            if fromDay > toDay {
                return deltaMonth + 1
            } else {
                return deltaMonth
            }
        } else { return nil }
    }
    
    func deltaMonth(fromDate: String, toDate: String, format: PhotoructionDateFormat) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        dateFormatter.locale = Locale(identifier: "ja_JP")
        guard let from = dateFormatter.date(from: fromDate),
            let to = dateFormatter.date(from: toDate) else { return nil }
        return deltaMonth(from: from, to: to)
    }
    
    func deltaDays(fromDate: String, toDate: String, format: PhotoructionDateFormat) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let calendar = Calendar(identifier: .gregorian)
        guard let from = dateFormatter.date(from: fromDate),
            let to = dateFormatter.date(from: toDate) else { return nil }
        return calendar.dateComponents([.day], from: from, to: to).day
    }
    
    func deltaDays(from: Date, to: Date) -> Int? {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.dateComponents([.day], from: from, to: to).day
    }
    
    func days(of date: String, format: PhotoructionDateFormat) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let calendar = Calendar(identifier: .gregorian)
        guard let date = dateFormatter.date(from: date) else {
            return nil
        }
        guard let days = calendar.range(of: .day, in: .month, for: date) else {
            return nil
        }
        return days.count
    }
    
    func days(of date: Date) -> Int? {
        let calendar = Calendar(identifier: .gregorian)
        guard let days = calendar.range(of: .day, in: .month, for: date) else {
            return nil
        }
        return days.count
    }
    
    func addDay(day: Int, fromDate: String, format: PhotoructionDateFormat) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let calendar = Calendar(identifier: .gregorian)
        guard let date = dateFormatter.date(from: fromDate) else {
            return nil
        }
        return calendar.date(byAdding: .day, value: day, to: date)
    }
    
    func add(day: Int, from: Date) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(byAdding: .day, value: day, to: from)
    }
    
    func add(month: Int, fromDate: String, format: PhotoructionDateFormat) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let calendar = Calendar(identifier: .gregorian)
        guard let date = dateFormatter.date(from: fromDate) else {
            return nil
        }
        return calendar.date(byAdding: .month, value: month, to: date)
    }
    
    func dateComponents(date: Date) -> (String, String, String, String)? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy|M|d|E"
        if Locale.preferredLanguages.first?.contains("ja") == true {
            dateFormatter.locale = Locale(identifier: "ja_JP")
        } else {
            dateFormatter.locale = Locale(identifier: "en_US")
        }
        let str = dateFormatter.string(from: date)
        let arr = str.components(separatedBy: "|")
        guard arr.count == 4 else {
            return nil
        }
        return (arr[0], arr[1], arr[2], arr[3])
    }
    
    func isEndOfMonth(date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let comp = calendar.dateComponents([.year, .month, .day], from: date)
        return comp.day == calendar.range(of: .day, in: .month, for: date)?.count
    }
    
    func isMiddleOfMonth(date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let comp = calendar.dateComponents([.year, .month, .day], from: date)
        return comp.day == 15
    }
    
    func isBeginningOfMonth(date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let comp = calendar.dateComponents([.year, .month, .day], from: date)
        return comp.day == 1
    }
    
    private func makeJSTDateFormatter(_ format: PhotoructionDateFormat) -> DateFormatter {
        return makeDateFormatter(format, timeZone: PhotoructionTimeZone.JST)
    }
    
    private func makeDateFormatter(_ format: PhotoructionDateFormat, timeZone: PhotoructionTimeZone) -> DateFormatter {
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        formatter.locale = NSLocale.system
        if timeZone == PhotoructionTimeZone.Locale {
            formatter.timeZone = TimeZone.autoupdatingCurrent
        } else {
            formatter.timeZone = TimeZone(identifier: timeZone.rawValue)
        }
        formatter.dateFormat = format.rawValue
        return formatter
    }
    
    private func dateFormatterMaker(_ format: String, timeZone: TimeZone) -> DateFormatter {
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        if Locale.preferredLanguages.first?.contains("ja") == true {
            formatter.locale = Locale(identifier: "ja_JP")
        } else {
            formatter.locale = Locale(identifier: "en_US")
        }
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }
}
