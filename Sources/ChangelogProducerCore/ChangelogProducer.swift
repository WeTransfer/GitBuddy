//
//  ChangelogProducer.swift
//  
//
//  Created by Antoine van der Lee on 10/01/2020.
//

import Foundation
import Shell

public final class ChangelogProducer {
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    /// Input parameters:
    /// - Target branch, defaults to master
    public func run() throws {
        let shell = Shell()

        print("Fetching tags")
        _ = shell.sync(["git", "fetch", "--tags"])

        // git tag --sort=committerdate | tail -1
        let latestTag = try shell.capture(["git", "tag", "--sort=committerdate", "| tail -1"]).get()
        print("Latest tag is \(latestTag)")
        let tagCreationDate = try Shell().capture(["git", "log", "-1", "--format=%ai", latestTag]).get()
        print("Tag \(latestTag) is created at \(tagCreationDate)")

        /// Fetch last release from GitHub
        /// Fetch PRs after last released tag creation date
    }
}
