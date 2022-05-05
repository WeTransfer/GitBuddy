//
//  PullRequestFetcherTests.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import XCTest
import OctoKit
import Mocker
@testable import GitBuddyCore

final class PullRequestFetcherTests: XCTestCase {

    private let octoKit: Octokit = Octokit()
    private var urlSession: URLSession!

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

    func testFetchingPullRequest() throws {
        Mocker.mockPullRequests()
        let release = try Tag.latest()
        let project = GITProject(organisation: "WeTransfer", repository: "Diagnostics")
        let fetcher = PullRequestFetcher(octoKit: octoKit, baseBranch: "master", project: project)
        let pullRequests = try fetcher.fetchAllBetween(release.created, and: Date(), using: urlSession)
        XCTAssertEqual(pullRequests.count, 2)
        XCTAssertEqual(pullRequests[0].title, "Add charset utf-8 to html head 🫥")
        XCTAssertEqual(pullRequests[1].title, "Fix warning occurring in pod library because of importing style.css #trivial")
    }

}
