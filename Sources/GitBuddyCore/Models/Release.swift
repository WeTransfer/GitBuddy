//
//  Release.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

struct Release: ShellInjectable {
    enum Error: Swift.Error {
        case missingTagCreationDate
    }

    let tag: String
    let created: Date

    init(tag: String) throws {
        let tagCreationDate = Self.shell.execute(.tagCreationDate(tag: tag))
        Log.debug("Tag \(tag) is created at \(tagCreationDate)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        self.tag = tag
        guard let date = dateFormatter.date(from: tagCreationDate) else {
            throw Error.missingTagCreationDate
        }
        self.created = date
    }

    static func latest() throws -> Release {
        Log.debug("Fetching tags")
        shell.execute(.fetchTags)
        let latestTag = shell.execute(.latestTag)
        Log.debug("Latest tag is \(latestTag)")

        return try Release(tag: latestTag)
    }
}
