//
//  ChangelogProducerTests.swift
//  ChangelogProducer
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import XCTest
@testable import ChangelogProducerCore
import Mocker

final class ChangelogProducerTests: XCTestCase {

    private let environment = ["DANGER_GITHUB_API_TOKEN": UUID().uuidString]
    private var urlSession: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
        ShellInjector.shell = MockedShell.self
        MockedShell.mockRelease(tag: "1.0.0")
        MockedShell.mockGITProject()
    }

    override func tearDown() {
        super.tearDown()
        MockedShell.commandMocks.removeAll()
        urlSession = nil
    }

    /// It should correctly output the changelog.
    func testChangelogOutput() throws {
        Mocker.mockPullRequests(token: environment.values.first!)
        Mocker.mockForIssueNumber(39, token: environment.values.first!)
        MockedShell.mockGITProject(organisation: "WeTransfer", repository: "Diagnostics")
        let changelog = try ChangelogProducer(environment: environment, arguments: ["ChangelogProducer"]).run(using: urlSession)
        XCTAssertEqual(changelog, "- Add charset utf-8 to html head ([#50](https://github.com/WeTransfer/Diagnostics/pull/50)) via @AvdLee\n- Get warning for file \'style.css\' after building ([#39](https://github.com/WeTransfer/Diagnostics/issues/39)) via @AvdLee")
    }

    /// It should use the `DANGER_GITHUB_API_TOKEN` for setting up OctoKit.
    func testOctoKitConfiguration() throws {
        let token = UUID().uuidString
        let producer = try ChangelogProducer(environment: ["DANGER_GITHUB_API_TOKEN": token], arguments: ["ChangelogProducer"])
        XCTAssertEqual(producer.octoKit.configuration.accessToken, token)
    }

    /// It should throw an error if the `DANGER_GITHUB_API_TOKEN` was not set.
    func testMissingDangerAPIToken() {
        do {
            _ = try ChangelogProducer()
        } catch {
            XCTAssertEqual(error as? ChangelogProducer.Error, .missingDangerToken)
        }
    }

    /// It should enable verbose logging.
    func testVerboseLogging() throws {
        XCTAssertFalse(Log.isVerbose)
        _ = try ChangelogProducer(environment: environment, arguments: ["ChangelogProducer", "--verbose"])
        XCTAssertTrue(Log.isVerbose)
    }

    /// It should default to master branch.
    func testDefaultBranch() throws {
        let producer = try ChangelogProducer(environment: environment, arguments: ["ChangelogProducer"])
        XCTAssertEqual(producer.base, "master")
    }

    /// It should accept a different branch as base argument.
    func testBaseBranchArgument() throws {
        let producer = try ChangelogProducer(environment: environment, arguments: ["ChangelogProducer", "-b", "develop"])
        XCTAssertEqual(producer.base, "develop")
    }

    /// It should use the latest tag by default for the latest release.
    func testLatestReleaseUsingLatestTag() throws {
        let tag = "2.1.3"
        let date = Date()
        MockedShell.mockRelease(tag: tag, date: date)

        let producer = try ChangelogProducer(environment: environment, arguments: ["ChangelogProducer"])

        XCTAssertEqual(producer.latestRelease.tag, tag)
        XCTAssertEqual(Int(producer.latestRelease.created.timeIntervalSince1970), Int(date.timeIntervalSince1970))
    }

    /// It should use a tag passed as argument over the latest tag.
    func testReleaseUsingTagArgument() throws {
        let tag = "3.0.2"
        let date = Date()
        MockedShell.mockRelease(tag: tag, date: date)

        let producer = try ChangelogProducer(environment: environment, arguments: ["ChangelogProducer", "-s", tag])
        XCTAssertEqual(producer.latestRelease.tag, tag)
        XCTAssertEqual(Int(producer.latestRelease.created.timeIntervalSince1970), Int(date.timeIntervalSince1970))
    }

    /// It should parse the current GIT project correctly.
    func testGITProjectParsing() throws {
        let organisation = "WeTransfer"
        let repository = "ChangelogProducer"
        MockedShell.mockGITProject(organisation: organisation, repository: repository)

        let producer = try ChangelogProducer(environment: environment, arguments: ["ChangelogProducer"])
        XCTAssertEqual(producer.project.organisation, organisation)
        XCTAssertEqual(producer.project.repository, repository)
    }

}
