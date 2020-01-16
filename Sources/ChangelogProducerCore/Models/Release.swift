//
//  Release.swift
//  ChangelogProducerCore
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import Foundation

struct Release: ShellInjectable {
    enum Error: Swift.Error {
        case missingTagCreationDate
    }

    let tag: String
    let created: Date

    init(tag: String) throws {
        let tagCreationDate = Self.shell.execute("git log -1 --format=%ai \(tag)").filter { !$0.isNewline }
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
        shell.execute("git fetch --tags")
        let latestTag = shell.execute("git tag --sort=committerdate | tail -1").filter { !$0.isNewline && !$0.isWhitespace }
        Log.debug("Latest tag is \(latestTag)")

        return try Release(tag: latestTag)
    }
}
