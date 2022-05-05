//
//  ChangelogCommand.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 09/04/2020.
//

import ArgumentParser
import Foundation

struct ChangelogCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(commandName: "changelog", abstract: "Create a changelog for GitHub repositories")

    @Option(name: .shortAndLong, help: "The tag to use as a base. Defaults to the latest tag.")
    private var sinceTag: String?

    @Option(name: .shortAndLong, help: "The base branch to compare with. Defaults to master.")
    private var baseBranch: String?

    @Flag(name: .customLong("sections"), help: "Whether the changelog should be split into sections. Defaults to false.")
    private var isSectioned: Bool = false

    @Flag(name: .long, help: "Show extra logging for debugging purposes")
    private var verbose: Bool = false

    func run() throws {
        Log.isVerbose = verbose

        let sinceTag = self.sinceTag.map { ChangelogProducer.Since.tag(tag: $0) }
        let changelogProducer = try ChangelogProducer(since: sinceTag ?? .latestTag,
                                                      baseBranch: baseBranch)
        let changelog = try changelogProducer.run(isSectioned: isSectioned)
        Log.message(changelog.description)
    }
}
