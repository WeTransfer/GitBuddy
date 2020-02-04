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

    @discardableResult func run(using arguments: ArgumentParser.Result, environment: [String: String]) throws -> String {
        let changelogProducer = try ChangelogProducer(sinceTag: arguments.get(sinceTag),
                                                      baseBranch: arguments.get(baseBranch),
                                                      verbose: arguments.get(verbose) ?? false,
                                                      environment: environment)
        return try changelogProducer.run()
    }
}

/// Capable of producing a changelog based on input parameters.
final class ChangelogProducer: URLSessionInjectable {

    enum Error: Swift.Error {
        case missingDangerToken
    }

    let octoKit: Octokit
    let base: Branch
    let latestRelease: Release
    let project: GITProject

    init(sinceTag: String?, baseBranch: Branch?, verbose: Bool, environment: [String: String]) throws {
        guard let gitHubAPIToken = environment["DANGER_GITHUB_API_TOKEN"] else {
            throw Error.missingDangerToken
        }

        let config = TokenConfiguration(gitHubAPIToken)
        octoKit = Octokit(config)

        // The first argument is always the executable, drop it
        Log.isVerbose = verbose

        if let tag = sinceTag {
            latestRelease = try Release(tag: tag)
        } else {
            latestRelease = try Release.latest()
        }
        base = baseBranch ?? "master"
        project = GITProject.current()
    }

    @discardableResult public func run() throws -> String {
        Log.debug("Latest release is \(latestRelease.tag)")

        let pullRequestsFetcher = PullRequestFetcher(octoKit: octoKit, base: base, project: project)
        let pullRequests = try pullRequestsFetcher.fetchAllAfter(latestRelease, using: urlSession)
        let items = ChangelogItemsFactory(octoKit: octoKit, pullRequests: pullRequests, project: project).items(using: urlSession)
        let changelog = ChangelogBuilder(items: items).build()

        Log.debug("Generated changelog:\n")
        Log.message(changelog)

        return changelog
    }
}
