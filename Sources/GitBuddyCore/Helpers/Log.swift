//
//  Log.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

enum Log {
    static var isVerbose: Bool = false

    /// Can be used to catch output for testing purposes.
    static var pipe: ((_ message: String) -> Void)?

    static func debug(_ message: String) {
        guard isVerbose else { return }
        print(message)
    }

    static func message(_ message: String) {
        print(message)
    }

    private static func print(_ message: String) {
        pipe?(message)
        Swift.print(message)
    }
}
