//
//  ChangelogBuilder.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 16/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit

struct ChangelogBuilder {
    let items: [ChangelogItem]

    func build() -> String {
        return items
            .compactMap { $0.title }
            .filter { !$0.lowercased().contains("#trivial") }
            .map { "- \($0)" }
            .joined(separator: "\n")
    }
}
