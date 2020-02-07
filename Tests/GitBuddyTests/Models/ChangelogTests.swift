//
//  ChangelogTests.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 05/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import XCTest
@testable import GitBuddyCore

final class ChangelogTests: XCTestCase {

    /// It should report a single issue from a pull request correctly.
    func testPullRequestSingleIssue() {
        let pullRequest = MockedPullRequest(number: 0)
        let issue = MockedIssue(number: 0)
        let changelogItem = ChangelogItem(input: issue, closedBy: pullRequest)
        let changelog = Changelog(items: [changelogItem])

        XCTAssertEqual(changelog.itemIdentifiers, [0: [0]])
    }

    /// It should report multiple issues from a single pull request correctly.
    func testPullRequestMultipleIssues() {
        let pullRequest = MockedPullRequest(number: 0)
        let changelogItems = [
            ChangelogItem(input: MockedIssue(number: 0), closedBy: pullRequest),
            ChangelogItem(input: MockedIssue(number: 1), closedBy: pullRequest)
        ]
        let changelog = Changelog(items: changelogItems)

        XCTAssertEqual(changelog.itemIdentifiers, [0: [0, 1]])
    }

    /// It should report the pull request even though there's no linked issues.
    func testPullRequestNoIssues() {
        let pullRequest = MockedPullRequest(number: 0)
        let changelogItem = ChangelogItem(input: pullRequest, closedBy: pullRequest)
        let changelog = Changelog(items: [changelogItem])

        XCTAssertEqual(changelog.itemIdentifiers, [0: []])
    }

    /// It should create a changelog from its inputs.
    func testDescription() {
        let pullRequest = MockedPullRequest(number: 0)
        let issue = MockedIssue(title: "Fixed something")
        let changelogItem = ChangelogItem(input: issue, closedBy: pullRequest)
        let changelog = Changelog(items: [changelogItem])

        XCTAssertEqual(changelog.description, "- Fixed something")
    }
}
