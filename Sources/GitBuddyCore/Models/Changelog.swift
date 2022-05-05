//
//  Changelog.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 05/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit

typealias PullRequestID = Int
typealias IssueID = Int

/// Generalizes different types of changelogs with either single or multiple sections.
protocol Changelog: CustomStringConvertible {
    /// The pull requests ID and related issues IDs that are merged with the related release of this
    /// changelog. It is used to post update comments on corresponding PRs and issues when a release
    /// is published.
    var itemIdentifiers: [PullRequestID: [IssueID]] { get }
}

/// Represents a changelog with a single section of changelog items.
struct SingleSectionChangelog: Changelog {
    let description: String

    let itemIdentifiers: [PullRequestID: [IssueID]]

    init(items: [ChangelogItem]) {
        description = ChangelogBuilder(items: items).build()
        itemIdentifiers = items.reduce(into: [:]) { result, item in
            let pullRequestID: PullRequestID = item.closedBy.number

            if var pullRequestIssues = result[pullRequestID] {
                guard let issue = item.input as? ChangelogIssue else { return }
                pullRequestIssues.append(issue.number)
                result[pullRequestID] = pullRequestIssues
            } else if let issue = item.input as? ChangelogIssue {
                result[pullRequestID] = [issue.number]
            } else {
                result[pullRequestID] = []
            }
        }
    }
}

/// Represents a changelog with at least two sections, one for closed issues, the other for
/// merged pull requests.
struct SectionedChangelog: Changelog {
    let description: String

    let itemIdentifiers: [PullRequestID: [IssueID]]

    init(issues: [Issue], pullRequests: [PullRequest]) {
        description =
            """
            **Closed issues:**

            \(ChangelogBuilder(items: issues.map { ChangelogItem(input: $0, closedBy: $0) }).build())

            **Merged pull requests:**

            \(ChangelogBuilder(items: pullRequests.map { ChangelogItem(input: $0, closedBy: $0) }).build())
            """

        itemIdentifiers = pullRequests.reduce(into: [:]) { result, item in
            result[item.number] = item.body?.resolvingIssues()
        }
    }
}

extension PullRequest: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: PullRequest, rhs: PullRequest) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Issue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Issue, rhs: Issue) -> Bool {
        return lhs.id == rhs.id
    }
}
