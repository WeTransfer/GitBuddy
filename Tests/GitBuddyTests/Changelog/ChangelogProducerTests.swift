//
//  ChangelogProducerTests.swift
//  ChangelogProducerTests
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import XCTest
@testable import GitBuddyCore
import Mocker
import SPMUtility

final class ChangelogProducerTests: XCTestCase {

    private let configuration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        return configuration
    }()

    override func setUp() {
        super.setUp()
        ShellInjector.shell = MockedShell.self
        MockedShell.mockRelease(tag: "1.0.0")
        MockedShell.mockGITProject()
    }

    override func tearDown() {
        super.tearDown()
        MockedShell.commandMocks.removeAll()
    }

    /// It should correctly output the changelog.
    func testChangelogOutput() throws {
        Mocker.mockPullRequests()
        Mocker.mockForIssueNumber(39)
        MockedShell.mockGITProject(organisation: "WeTransfer", repository: "Diagnostics")
        let changelog = try GitBuddy.run(arguments: ["GitBuddy", "changelog"], configuration: configuration)
        XCTAssertEqual(changelog, "- Add charset utf-8 to html head ([#50](https://github.com/WeTransfer/Diagnostics/pull/50)) via @AvdLee\n- Get warning for file \'style.css\' after building ([#39](https://github.com/WeTransfer/Diagnostics/issues/39)) via @AvdLee")
    }

    /// It should default to master branch.
    func testDefaultBranch() throws {
        let producer = try ChangelogProducer(baseBranch: nil)
        XCTAssertEqual(producer.baseBranch, "master")
    }

    /// It should accept a different branch as base argument.
    func testBaseBranchArgument() throws {
        let producer = try ChangelogProducer(baseBranch: "develop")
        XCTAssertEqual(producer.baseBranch, "develop")
    }

    /// It should use the latest tag by default for the latest release adding 60 seconds to its creation date.
    func testLatestReleaseUsingLatestTag() throws {
        let tag = "2.1.3"
        let date = Date().addingTimeInterval(TimeInterval.random(in: 0..<100))
        MockedShell.mockRelease(tag: tag, date: date)

        let producer = try ChangelogProducer(baseBranch: nil)
        XCTAssertEqual(Int(producer.from.timeIntervalSince1970), Int(date.addingTimeInterval(60).timeIntervalSince1970))
    }

    /// It should use a tag passed as argument over the latest tag adding 60 seconds to its creation date..
    func testReleaseUsingTagArgument() throws {
        let expectedTag = "3.0.2"
        let date = Date().addingTimeInterval(TimeInterval.random(in: 0..<100))
        MockedShell.mockRelease(tag: expectedTag, date: date)

        let producer = try ChangelogProducer(since: .tag(tag: expectedTag), baseBranch: nil)
        guard case let ChangelogProducer.Since.tag(tag) = producer.since else {
            XCTFail("Wrong since used")
            return
        }
        XCTAssertEqual(tag, expectedTag)
        XCTAssertEqual(Int(producer.from.timeIntervalSince1970), Int(date.addingTimeInterval(60).timeIntervalSince1970))
    }

    /// It should parse the current GIT project correctly.
    func testGITProjectParsing() throws {
        let organisation = "WeTransfer"
        let repository = "GitBuddy"
        MockedShell.mockGITProject(organisation: organisation, repository: repository)

        let producer = try ChangelogProducer(baseBranch: nil)
        XCTAssertEqual(producer.project.organisation, organisation)
        XCTAssertEqual(producer.project.repository, repository)
    }

}
