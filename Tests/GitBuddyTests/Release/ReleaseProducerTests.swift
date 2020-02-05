//
//  ReleaseProducerTests.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 05/02/2020.
//

import XCTest
@testable import GitBuddyCore
import Mocker
import SPMUtility

final class ReleaseProducerTests: XCTestCase {

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

    /// It should enable verbose logging.
    func testVerboseLogging() throws {
        XCTAssertFalse(Log.isVerbose)
        _ = try GitBuddy.run(arguments: ["GitBuddy", "changelog", "--verbose"], configuration: configuration)
        XCTAssertTrue(Log.isVerbose)
    }

    /// It should default to master branch.
    func testDefaultBranch() throws {
        let producer = try ChangelogProducer(sinceTag: nil, baseBranch: nil, verbose: false)
        XCTAssertEqual(producer.base, "master")
    }

    /// It should accept a different branch as base argument.
    func testBaseBranchArgument() throws {
        let producer = try ChangelogProducer(sinceTag: nil, baseBranch: "develop", verbose: false)
        XCTAssertEqual(producer.base, "develop")
    }

    /// It should use the latest tag by default for the latest release.
    func testLatestReleaseUsingLatestTag() throws {
        let tag = "2.1.3"
        let date = Date()
        MockedShell.mockRelease(tag: tag, date: date)

        let producer = try ChangelogProducer(sinceTag: nil, baseBranch: nil, verbose: false)

        XCTAssertEqual(producer.baseRelease.tag, tag)
        XCTAssertEqual(Int(producer.baseRelease.created.timeIntervalSince1970), Int(date.timeIntervalSince1970))
    }

    /// It should use a tag passed as argument over the latest tag.
    func testReleaseUsingTagArgument() throws {
        let tag = "3.0.2"
        let date = Date()
        MockedShell.mockRelease(tag: tag, date: date)

        let producer = try ChangelogProducer(sinceTag: tag, baseBranch: nil, verbose: false)
        XCTAssertEqual(producer.baseRelease.tag, tag)
        XCTAssertEqual(Int(producer.baseRelease.created.timeIntervalSince1970), Int(date.timeIntervalSince1970))
    }

    /// It should parse the current GIT project correctly.
    func testGITProjectParsing() throws {
        let organisation = "WeTransfer"
        let repository = "GitBuddy"
        MockedShell.mockGITProject(organisation: organisation, repository: repository)

        let producer = try ChangelogProducer(sinceTag: nil, baseBranch: nil, verbose: false)
        XCTAssertEqual(producer.project.organisation, organisation)
        XCTAssertEqual(producer.project.repository, repository)
    }

}
