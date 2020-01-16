//
//  ChangelogProducerTests.swift
//  ChangelogProducer
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import XCTest
@testable import ChangelogProducerCore

final class ChangelogProducerTests: XCTestCase {

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

    /// It should use the `DANGER_GITHUB_API_TOKEN` for setting up OctoKit.
    func testOctoKitConfiguration() throws {
        let token = UUID().uuidString
        let producer = try ChangelogProducer(environment: ["DANGER_GITHUB_API_TOKEN": token], arguments: ["ChangelogProducer"])
        XCTAssertEqual(producer.octoKit.configuration.accessToken, token)
    }

    /// It should enable verbose logging.
    func testVerboseLogging() throws {
        XCTAssertFalse(Log.isVerbose)
        _ = try ChangelogProducer(arguments: ["ChangelogProducer", "--verbose"])
        XCTAssertTrue(Log.isVerbose)
    }

    /// It should default to master branch.
    func testDefaultBranch() throws {
        let producer = try ChangelogProducer(arguments: ["ChangelogProducer"])
        XCTAssertEqual(producer.base, "master")
    }

    /// It should accept a different branch as base argument.
    func testBaseBranchArgument() throws {
        let producer = try ChangelogProducer(arguments: ["ChangelogProducer", "-b", "develop"])
        XCTAssertEqual(producer.base, "develop")
    }

    /// It should use the latest tag by default for the latest release.
    func testLatestReleaseUsingLatestTag() throws {
        let tag = "2.1.3"
        let date = Date()
        MockedShell.mockRelease(tag: tag, date: date)

        let producer = try ChangelogProducer(arguments: ["ChangelogProducer"])

        XCTAssertEqual(producer.latestRelease.tag, tag)
        XCTAssertEqual(Int(producer.latestRelease.created.timeIntervalSince1970), Int(date.timeIntervalSince1970))
    }

    /// It should use a tag passed as argument over the latest tag.
    func testReleaseUsingTagArgument() throws {
        let tag = "3.0.2"
        let date = Date()
        MockedShell.mockRelease(tag: tag, date: date)

        let producer = try ChangelogProducer(arguments: ["ChangelogProducer", "-s", tag])
        XCTAssertEqual(producer.latestRelease.tag, tag)
        XCTAssertEqual(Int(producer.latestRelease.created.timeIntervalSince1970), Int(date.timeIntervalSince1970))
    }

    /// It should parse the current GIT project correctly.
    func testGITProjectParsing() throws {
        let organisation = "WeTransfer"
        let repository = "ChangelogProducer"
        MockedShell.mockGITProject(organisation: organisation, repository: repository)

        let producer = try ChangelogProducer(arguments: ["ChangelogProducer"])
        XCTAssertEqual(producer.project.organisation, organisation)
        XCTAssertEqual(producer.project.repository, repository)
    }

}
