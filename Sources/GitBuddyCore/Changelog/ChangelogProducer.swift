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
    static let command = "changelog"
    static let description = "Create a changelog for GitHub repositories"
    let sinceTag: OptionArgument<String>
    let baseBranch: OptionArgument<String>

    init(subparser: ArgumentParser) {
        sinceTag = subparser.add(option: "--since-tag", shortName: "-s", kind: String.self, usage: "The tag to use as a base. Defaults to the latest tag.")
        baseBranch = subparser.add(option: "--base-branch", shortName: "-b", kind: String.self, usage: "The base branch to compare with. Defaults to master.")
    }

    @discardableResult func run(using arguments: ArgumentParser.Result) throws -> String {
        let changelogProducer = try ChangelogProducer(sinceTag: arguments.get(sinceTag),
                                                      baseBranch: arguments.get(baseBranch))

        Log.debug("Result of creating the changelog:\n")
        return try changelogProducer.run().description
    }
}

/// Capable of producing a changelog based on input parameters.
final class ChangelogProducer: URLSessionInjectable {

    private lazy var octoKit: Octokit = Octokit()
    let base: Branch
    let baseTag: Tag
    let project: GITProject

    init(sinceTag: String?, baseBranch: Branch?) throws {
        if let tag = sinceTag {
            baseTag = try Tag(name: tag)
        } else {
            baseTag = try Tag.latest()
        }
        base = baseBranch ?? "master"
        project = GITProject.current()
    }

    @discardableResult public func run() throws -> Changelog {
        Log.debug("Getting all changes happened after \(baseTag.name)")

        let pullRequestsFetcher = PullRequestFetcher(octoKit: octoKit, base: base, project: project)
        let pullRequests = try pullRequestsFetcher.fetchAllAfter(baseTag, using: urlSession)
        let items = ChangelogItemsFactory(octoKit: octoKit, pullRequests: pullRequests, project: project).items(using: urlSession)
        return Changelog(items: items)
    }
}
