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
        let sinceTag = arguments.get(self.sinceTag).map { ChangelogProducer.Since.tag(tag: $0) }
        let changelogProducer = try ChangelogProducer(since: sinceTag ?? .latestTag,
                                                      baseBranch: arguments.get(baseBranch))

        Log.debug("Result of creating the changelog:\n")
        return try changelogProducer.run().description
    }
}

/// Capable of producing a changelog based on input parameters.
final class ChangelogProducer: URLSessionInjectable {

    enum Since {
        case date(date: Date)
        case tag(tag: String)
        case latestTag

        func get() throws -> Date {
            switch self {
            case .date(let date):
                return date
            case .tag(let tag):
                return try Tag(name: tag).created
            case .latestTag:
                return try Tag.latest().created
            }
        }
    }

    private lazy var octoKit: Octokit = Octokit()
    let baseBranch: Branch
    let since: Since
    let from: Date
    let to: Date
    let project: GITProject

    init(since: Since = .latestTag, to: Date = Date(), baseBranch: Branch?) throws {
        self.to = to
        self.since = since

        let from = try since.get()

        if from != self.to {
            self.from = from
        } else {
            Log.debug("From date could not be determined. Using today minus 30 days as the base date")
            self.from = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        }

        Log.debug("Getting all changes between \(self.from) and \(self.to)")
        self.baseBranch = baseBranch ?? "master"
        project = GITProject.current()
    }

    @discardableResult public func run() throws -> Changelog {
        let pullRequestsFetcher = PullRequestFetcher(octoKit: octoKit, baseBranch: baseBranch, project: project)
        let pullRequests = try pullRequestsFetcher.fetchAllBetween(from, and: to, using: urlSession)
        let items = ChangelogItemsFactory(octoKit: octoKit, pullRequests: pullRequests, project: project).items(using: urlSession)
        return Changelog(items: items)
    }
}
