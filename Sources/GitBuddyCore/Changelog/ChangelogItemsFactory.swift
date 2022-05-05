//
//  ChangelogItemsFactory.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 16/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit

struct ChangelogItemsFactory {
    let octoKit: Octokit
    let pullRequests: [PullRequest]
    let project: GITProject

    func items(using session: URLSession = URLSession.shared) -> [ChangelogItem] {
        return pullRequests.flatMap { pullRequest -> [ChangelogItem] in
            let issuesResolver = IssuesResolver(octoKit: octoKit, project: project, input: pullRequest)
            guard let resolvedIssues = issuesResolver.resolve(using: session), !resolvedIssues.isEmpty else {
                return [ChangelogItem(input: pullRequest, closedBy: pullRequest)]
            }
            return resolvedIssues.map { issue -> ChangelogItem in
                ChangelogItem(input: issue, closedBy: pullRequest)
            }
        }
    }
}
