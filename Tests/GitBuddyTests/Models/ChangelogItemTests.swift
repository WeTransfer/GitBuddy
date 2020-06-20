//
//  ChangelogItemTests.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import XCTest
@testable import GitBuddyCore
import OctoKit

final class ChangelogItemTests: XCTestCase {

    /// It should return `nil` if there's no title.
    func testNilTitle() {
        let item = ChangelogItem(input: MockChangelogInput(), closedBy: MockedPullRequest())
        XCTAssertNil(item.title)
    }

    /// It should return `title` as is.
    func testFirstUpperCaseTitle() {
        let item = ChangelogItem(input: MockChangelogInput(title: "Update README.md"), closedBy: MockedPullRequest())
        XCTAssertEqual(item.title, "Update README.md")
    }

    /// It should capitalize first word in `title`
    func testFirstLowerCaseTitle() {
        let item = ChangelogItem(input: MockChangelogInput(title: "ignoring query example"), closedBy: MockedPullRequest())
        XCTAssertEqual(item.title, "Ignoring query example")
    }

    /// It should correctly display the number and URL.
    func testNumberURL() {
        let input = MockChangelogInput(number: 1, title: UUID().uuidString, htmlURL: URL(string: "https://www.fakeurl.com")!)
        let item = ChangelogItem(input: input, closedBy: MockedPullRequest())
        XCTAssertEqual(item.title, "\(input.title!) ([#1](https://www.fakeurl.com))")
    }

    /// It should show the user if possible.
    func testUser() {
        let input = PullRequestsJSON.data(using: .utf8)!.mapJSON(to: [PullRequest].self).first!
        input.htmlURL = nil
        let item = ChangelogItem(input: input, closedBy: input)
        XCTAssertEqual(item.title, "\(input.title!) via [@AvdLee](https://github.com/AvdLee)")
    }

    /// It should fallback to the assignee if the user is nil for Pull Requests.
    func testAssigneeFallback() {
        let input = PullRequestsJSON.data(using: .utf8)!.mapJSON(to: [PullRequest].self).first!
        input.user = nil
        input.htmlURL = nil
        let item = ChangelogItem(input: input, closedBy: input)
        XCTAssertEqual(
            item.title,
            "\(input.title!) via [@kairadiagne](https://github.com/kairadiagne)"
        )
    }

    /// It should combine the title, number and user.
    func testTitleNumberUser() {
        let input = MockChangelogInput(number: 1, title: UUID().uuidString, htmlURL: URL(string: "https://www.fakeurl.com")!)
        let closedBy = MockedPullRequest(username: "Henk")
        let item = ChangelogItem(input: input, closedBy: closedBy)
        XCTAssertEqual(
            item.title,
            "\(input.title!) ([#1](https://www.fakeurl.com)) via [@Henk](https://github.com/Henk)"
        )
    }

}
