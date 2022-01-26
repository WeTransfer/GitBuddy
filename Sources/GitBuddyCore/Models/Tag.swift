//
//  Tag.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

struct Tag: ShellInjectable, Encodable {
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

    /// Creates a new Tag instance.
    /// - Parameters:
    ///   - name: The name to use for the tag.
    ///   - created: The creation date to use. If `nil`, the date is fetched using the `git` terminal command. See `fallbackDate` for setting a date if this operation fails due to a missing tag.
    /// - Throws: An error if the creation date could not be found.
    init(name: String, created: Date? = nil) throws {
        self.name = name

        if let created = created {
            self.created = created
        } else {
            let tagCreationDate = Self.shell.execute(.tagCreationDate(tag: name))
            if tagCreationDate.isEmpty {
                Log.debug("Tag creation date could not be found")
                throw Error.missingTagCreationDate
            }

            Log.debug("Tag \(name) is created at \(tagCreationDate)")

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            guard let date = Formatter.gitDateFormatter.date(from: tagCreationDate) else {
                throw Error.missingTagCreationDate
            }
            self.created = date
        }
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
