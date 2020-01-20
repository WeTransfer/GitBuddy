//
//  ChangelogItemsFactoryTests.swift
//  ChangelogProducerTests
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import XCTest
@testable import ChangelogProducerCore
@testable import OctoKit
import Mocker

final class ChangelogItemsFactoryTests: XCTestCase {

    private let octoKit: Octokit = Octokit()
    private var urlSession: URLSession!
    private let project = GITProject(organisation: "WeTransfer", repository: "Diagnostics")

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
        ShellInjector.shell = MockedShell.self
    }

    override func tearDown() {
        super.tearDown()
        urlSession = nil
    }

    /// It should return the pull request only if no referencing issues are found.
    func testCreatingItems() {
        let pullRequest = PullRequestsJSON.data(using: .utf8)!.mapJSON(to: [PullRequest].self).first!
        let factory = ChangelogItemsFactory(octoKit: octoKit, pullRequests: [pullRequest], project: project)
        let items = factory.items(using: urlSession)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.input.title, pullRequest.title)
        XCTAssertEqual(items.first?.closedBy.title, pullRequest.title)
    }

    /// It should return the referencing issue with the pull request.
    func testReferencingIssue() {
        let pullRequest = PullRequestsJSON.data(using: .utf8)!.mapJSON(to: [PullRequest].self).last!
        let issue = IssueJSON.data(using: .utf8)!.mapJSON(to: Issue.self)
        let factory = ChangelogItemsFactory(octoKit: octoKit, pullRequests: [pullRequest], project: project)
        Mocker.mockForIssueNumber(39)
        let items = factory.items(using: urlSession)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.input.title, issue.title)
        XCTAssertEqual(items.first?.closedBy.title, pullRequest.title)
    }

}
