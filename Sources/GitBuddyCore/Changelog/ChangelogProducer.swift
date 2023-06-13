//
//  GitBuddy.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit

/// Capable of producing a changelog based on input parameters.
final class ChangelogProducer: URLSessionInjectable {
    enum Since {
        case date(date: Date)
        case tag(tag: String)
        case latestTag

        /// Gets the date for the current Since property.
        /// In the case of a tag, we add 60 seconds to make sure that the Changelog does not include the commit that
        /// is used for creating the tag.
        /// This is needed as the tag creation date equals the commit creation date.
        func get() throws -> Date {
            switch self {
            case .date(let date):
                return date
            case .tag(let tag):
                return try Tag(name: tag).created.addingTimeInterval(60)
            case .latestTag:
                return try Tag.latest().created.addingTimeInterval(60)
            }
        }
    }

    private lazy var octoKit: Octokit = .init()
    let baseBranch: Branch
    let since: Since
    let from: Date
    let to: Date
    let project: GITProject
    let useGitHubReleaseNotes: Bool
    let tagName: String?
    let targetCommitish: String?
    let previousTagName: String?

    init(
        since: Since = .latestTag,
        to: Date = Date(),
        baseBranch: Branch?,
        useGitHubReleaseNotes: Bool = false,
        tagName: String? = nil,
        targetCommitish: String? = nil,
        previousTagName: String? = nil
    ) throws {
        try Octokit.authenticate()

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
        self.useGitHubReleaseNotes = useGitHubReleaseNotes
        self.tagName = tagName
        self.targetCommitish = targetCommitish
        self.previousTagName = previousTagName
    }

    @discardableResult public func run(isSectioned: Bool) throws -> Changelog {
        if useGitHubReleaseNotes, let tagName, let targetCommitish, let previousTagName {
            return try GitHubReleaseNotesGenerator(
                octoKit: octoKit,
                project: project,
                tagName: tagName,
                targetCommitish: targetCommitish,
                previousTagName: previousTagName
            ).generate(using: urlSession)
        } else {
            return try generateChangelogUsingPRsAndIssues(isSectioned: isSectioned)
        }
    }

    private func generateChangelogUsingPRsAndIssues(isSectioned: Bool) throws -> Changelog {
        let pullRequestsFetcher = PullRequestFetcher(octoKit: octoKit, baseBranch: baseBranch, project: project)
        let pullRequests = try pullRequestsFetcher.fetchAllBetween(from, and: to, using: urlSession)

        if Log.isVerbose {
            Log.debug("\nChangelog will use the following pull requests as input:")
            pullRequests.forEach { pullRequest in
                guard let title = pullRequest.title, let mergedAt = pullRequest.mergedAt else { return }
                Log.debug("- #\(pullRequest.number): \(title), merged at: \(mergedAt)\n")
            }
        }

        if isSectioned {
            let issuesFetcher = IssuesFetcher(octoKit: octoKit, project: project)
            let issues = try issuesFetcher.fetchAllBetween(from, and: to, using: urlSession)

            if Log.isVerbose {
                Log.debug("\nChangelog will use the following issues as input:")
                issues.forEach { issue in
                    guard let title = issue.title, let closedAt = issue.closedAt else { return }
                    Log.debug("- #\(issue.number): \(title), closed at: \(closedAt)\n")
                }
            }

            return SectionedChangelog(issues: issues, pullRequests: pullRequests)
        } else {
            let items = ChangelogItemsFactory(
                octoKit: octoKit,
                pullRequests: pullRequests,
                project: project
            ).items(using: urlSession)

            Log.debug("Result of creating the changelog:")
            return SingleSectionChangelog(items: items)
        }
    }
}
