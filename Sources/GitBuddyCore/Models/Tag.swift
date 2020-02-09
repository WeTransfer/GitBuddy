//
//  Tag.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

struct Tag: ShellInjectable {
    enum Error: Swift.Error, CustomStringConvertible {
        case missingTagCreationDate
        case noTagsAvailable

        var description: String {
            switch self {
            case .missingTagCreationDate:
                return "Tag creation date could not be determined"
            case .noTagsAvailable:
                return "There's no tags available"
            }
        }

    }

    let name: String
    let created: Date

    init(name: String) throws {
        let tagCreationDate = Self.shell.execute(.tagCreationDate(tag: name))
        Log.debug("Tag \(name) is created at \(tagCreationDate)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        self.name = name
        guard let date = dateFormatter.date(from: tagCreationDate) else {
            throw Error.missingTagCreationDate
        }
        self.created = date
    }

    static func latest() throws -> Self {
        Log.debug("Fetching tags")
        shell.execute(.fetchTags)
        let latestTag = shell.execute(.latestTag)

        guard !latestTag.isEmpty else { throw Error.noTagsAvailable }

        Log.debug("Latest tag is \(latestTag)")

        return try Tag(name: latestTag)
    }
}
