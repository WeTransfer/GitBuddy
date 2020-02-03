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

/// Capable of producing a changelog based on input parameters.
public final class ChangelogProducer: Command {

    enum Error: Swift.Error {
        case missingDangerToken
    }

    let command = "changelog"
    let overview = "Create a changelog for GitHub repositories"

    let sinceTag: OptionArgument<String>
    let baseBranch: OptionArgument<String>
    let verbose: OptionArgument<Bool>
    var session: URLSession = URLSession.shared

    public init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        sinceTag = subparser.add(option: "--sinceTag", shortName: "-s", kind: String.self, usage: "The tag to use as a base")
        baseBranch = subparser.add(option: "--baseBranch", shortName: "-b", kind: String.self, usage: "The base branch to compare with")
        verbose = subparser.add(option: "--verbose", kind: Bool.self, usage: "Show extra logging for debugging purposes")
    }

    @discardableResult public func run(arguments: ArgumentParser.Result, environment: [String: String]) throws -> String {
        guard let gitHubAPIToken = environment["DANGER_GITHUB_API_TOKEN"] else {
            throw Error.missingDangerToken
        }

        let config = TokenConfiguration(gitHubAPIToken)
        let octoKit = Octokit(config)

        Log.isVerbose = arguments.get(verbose) ?? false

        let latestRelease: Release
        if let tag = arguments.get(sinceTag) {
            latestRelease = try Release(tag: tag)
        } else {
            latestRelease = try Release.latest()
        }
        Log.debug("Latest release is \(latestRelease.tag)")

        let base = arguments.get(baseBranch) ?? "master"
        let project = GITProject.current()

        let pullRequestsFetcher = PullRequestFetcher(octoKit: octoKit, base: base, project: project)
        let pullRequests = try pullRequestsFetcher.fetchAllAfter(latestRelease, using: session)
        let items = ChangelogItemsFactory(octoKit: octoKit, pullRequests: pullRequests, project: project).items(using: session)
        let changelog = ChangelogBuilder(items: items).build()

        Log.debug("Generated changelog:\n")
        Log.message(changelog)

        return changelog
    }
}
