//
//  String+URL.swift
//  GitHubSignupUsingDriver
//
//  Created by 藤門莉生 on 2023/03/06.
//

extension String {
    var urlPathEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }
}
