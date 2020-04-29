//
//  NonNameWords.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/23/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

import Foundation

struct NonNameWords {
    static let blacklist: Set = ["customer", "debit", "visa", "mastercard", "navy", "thru", "good",
                                 "authorized", "signature", "wells", "navy", "credit", "federal",
                                 "union", "bank", "valid", "llc", "business", "netspend",
                                 "goodthru", "chase", "fargo", "hsbc", "usaa", "chaseo", "commerce",
                                 "last", "of", "check", "card", "inc", "first", "member", "since",
                                 "american", "express", "republic"]

    static func match(_ text: String) -> Bool {
        let lowerCase = text.lowercased()
        return blacklist.contains(lowerCase)
    }
}
