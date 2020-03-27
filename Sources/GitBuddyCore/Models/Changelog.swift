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

protocol Changelog: CustomStringConvertible {
    /// The pull requests ID and related issues IDs that are merged with the related release of this changelog.
    var itemIdentifiers: [PullRequestID: [IssueID]] { get }
}

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

        itemIdentifiers = pullRequests.reduce(into: [:]) { (result, item) in
            result[item.number] = item.body?.resolvingIssues()
        }
    }
}

struct SingleSectionChangelog: Changelog {
    let description: String

    let itemIdentifiers: [PullRequestID: [IssueID]]

    init(items: [ChangelogItem]) {
        description = ChangelogBuilder(items: items).build()
        self.itemIdentifiers = items.reduce(into: [:], { (result, item) in
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
        })
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
