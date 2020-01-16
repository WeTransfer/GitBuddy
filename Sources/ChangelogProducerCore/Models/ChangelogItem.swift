//
//  ChangelogItem.swift
//  ChangelogProducerCore
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import Foundation
import OctoKit

protocol ChangelogInput {
    var number: Int? { get }
    var title: String? { get }
    var body: String? { get }
    var htmlURL: Foundation.URL? { get }
    var username: String? { get }
}

extension PullRequest: ChangelogInput {
    var username: String? { assignee?.login }
}
extension Issue: ChangelogInput {
    var username: String? { assignee?.login }
}

struct ChangelogItem {
    let input: ChangelogInput
    let closedBy: ChangelogInput

    var title: String? {
        guard var title = input.title else { return nil }
        if let number = input.number, let htmlURL = input.htmlURL {
            title += " ([#\(number)](\(htmlURL)))"
        }
        if let username = closedBy.username {
            title += " via @\(username)"
        }
        return title
    }
}
