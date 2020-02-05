//
//  GitBuddy.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit
import SPMUtility

struct ChangelogCommand: Command {
    let command = "changelog"
    let description = "Create a changelog for GitHub repositories"
    let sinceTag: OptionArgument<String>
    let baseBranch: OptionArgument<String>
    let verbose: OptionArgument<Bool>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: description)
        sinceTag = subparser.add(option: "--sinceTag", shortName: "-s", kind: String.self, usage: "The tag to use as a base")
        baseBranch = subparser.add(option: "--baseBranch", shortName: "-b", kind: String.self, usage: "The base branch to compare with")
        verbose = subparser.add(option: "--verbose", kind: Bool.self, usage: "Show extra logging for debugging purposes")
    }

    @discardableResult func run(using arguments: ArgumentParser.Result) throws -> String {
        let changelogProducer = try ChangelogProducer(sinceTag: arguments.get(sinceTag),
                                                      baseBranch: arguments.get(baseBranch),
                                                      verbose: arguments.get(verbose) ?? false)
        return try changelogProducer.run()
    }
}

/// Capable of producing a changelog based on input parameters.
final class ChangelogProducer: URLSessionInjectable {

    private lazy var octoKit: Octokit = Octokit()
    let base: Branch
    let baseRelease: Release
    let project: GITProject

    init(sinceTag: String?, baseBranch: Branch?, verbose: Bool) throws {
        // The first argument is always the executable, drop it
        Log.isVerbose = verbose

        if let tag = sinceTag {
            baseRelease = try Release(tag: tag)
        } else {
            baseRelease = try Release.latest()
        }
        base = baseBranch ?? "master"
        project = GITProject.current()
    }

    @discardableResult public func run() throws -> String {
        Log.debug("Getting all changes happened after \(baseRelease.tag)")

        let pullRequestsFetcher = PullRequestFetcher(octoKit: octoKit, base: base, project: project)
        let pullRequests = try pullRequestsFetcher.fetchAllAfter(baseRelease, using: urlSession)
        let items = ChangelogItemsFactory(octoKit: octoKit, pullRequests: pullRequests, project: project).items(using: urlSession)
        let changelog = ChangelogBuilder(items: items).build()

        Log.debug("Generated changelog:\n")
        Log.debug(changelog)

        return changelog
    }
}
