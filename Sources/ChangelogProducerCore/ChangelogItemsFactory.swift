//
//  ChangelogItemsFactory.swift
//  ChangelogProducerCore
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import Foundation
import OctoKit

struct ChangelogItemsFactory {
    let octoKit: Octokit
    let pullRequests: [PullRequest]
    let project: GITProject

    func items() -> [ChangelogItem] {
        return pullRequests.flatMap { pullRequest -> [ChangelogItem] in
            let issuesResolver = IssuesResolver(octoKit: octoKit, project: project, pullRequest: pullRequest)
            guard let resolvedIssues = issuesResolver.resolve(), !resolvedIssues.isEmpty else {
                return [ChangelogItem(input: pullRequest, closedBy: pullRequest)]
            }
            return resolvedIssues.map { issue -> ChangelogItem in
                return ChangelogItem(input: issue, closedBy: pullRequest)
            }
        }
    }
}
