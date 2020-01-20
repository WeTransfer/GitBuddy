//
//  Log.swift
//  ChangelogProducerCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

struct Log {
    static var isVerbose: Bool = false

    static func debug(_ message: Any) {
        guard isVerbose else { return }
        print(message)
    }

    static func message(_ message: Any) {
        print(message)
    }
}
