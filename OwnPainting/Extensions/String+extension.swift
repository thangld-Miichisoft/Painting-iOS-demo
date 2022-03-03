//
// Created by SHINYA HARADA on 2018/07/27.
// Copyright (c) 2018 shinyaharada. All rights reserved.
//

import Foundation
extension String {

    /// 正規表現でキャプチャした文字列を抽出する
    ///
    /// - Parameters:
    ///   - pattern: 正規表現
    ///   - group: 抽出するグループ番号(>=1)
    /// - Returns: 抽出した文字列
    func capture(pattern: String, group: Int) -> String? {
        let result = capture(pattern: pattern, group: [group])
        return result.isEmpty ? nil : result[0]
    }

    /// 正規表現でキャプチャした文字列を抽出する
    ///
    /// - Parameters:
    ///   - pattern: 正規表現
    ///   - group: 抽出するグループ番号(>=1)の配列
    /// - Returns: 抽出した文字列の配列
    func capture(pattern: String, group: [Int]) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        guard let matched = regex.firstMatch(in: self, range: NSRange(location: 0, length: self.count)) else {
            return []
        }

        return group.map { group -> String in
            return (self as NSString).substring(with: matched.range(at: group))
        }
    }
}

extension String {
    
    /// Convert to be JSON
    ///
    /// - Returns: [String: Any] json
    /// - Throws: Error if cannot convert
    func toJson() throws -> [String: Any]? {
        guard let data = self.data(using: .utf8) else { return nil }
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
    }
    
    func arrayJSON() throws -> [[String: Any]]? {
        guard let data = self.data(using: .utf8) else { return nil }
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]]
    }
}
