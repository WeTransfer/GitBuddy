//
//  ChangelogItem.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit

protocol ChangelogInput {
    var number: Int { get }
    var title: String? { get }
    var body: String? { get }
    var htmlURL: Foundation.URL? { get }
    var username: String? { get }
}
protocol ChangelogIssue: ChangelogInput { }
protocol ChangelogPullRequest: ChangelogInput { }

extension PullRequest: ChangelogPullRequest {
    var username: String? { user?.login ?? assignee?.login }
}

extension Issue: ChangelogIssue {
    var username: String? { assignee?.login }
}

struct ChangelogItem {
    let input: ChangelogInput
    let closedBy: ChangelogPullRequest

    var title: String? {
        guard var title = input.title else { return nil }
        if let htmlURL = input.htmlURL {
            title += " ([#\(input.number)](\(htmlURL)))"
        }
        if let username = closedBy.username {
            title += " via @\(username)"
        }
        return title
    }
}
