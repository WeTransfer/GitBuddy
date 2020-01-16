//
//  Release.swift
//  ChangelogProducerCore
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import Foundation

struct Release {
    let tag: String
    let created: Date

    init(tag: String) {
        let tagCreationDate = Shell.execute("git log -1 --format=%ai \(tag)").filter { !$0.isNewline }
        Log.debug("Tag \(tag) is created at \(tagCreationDate)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        self.tag = tag
        self.created = dateFormatter.date(from: tagCreationDate)!
    }

    static func latest() -> Release {
        Log.debug("Fetching tags")
        Shell.execute("git fetch --tags")
        let latestTag = Shell.execute("git tag --sort=committerdate | tail -1").filter { !$0.isNewline && !$0.isWhitespace }
        Log.debug("Latest tag is \(latestTag)")

        return Release(tag: latestTag)
    }
}
