//
//  DateFormatters.swift
//  
//
//  Created by Antoine van der Lee on 25/01/2022.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

enum Formatter {
    static let gitDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()
}
