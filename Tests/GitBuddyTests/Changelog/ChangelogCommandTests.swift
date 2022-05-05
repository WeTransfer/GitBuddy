//
//  ChangelogCommandTests.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 09/04/2020.
//

@testable import GitBuddyCore
import Mocker
import OctoKit
import XCTest

final class ChangelogCommandTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Octokit.protocolClasses = [MockingURLProtocol.self]
        mockGITAuthentication()
        ShellInjector.shell = MockedShell.self
        MockedShell.mockRelease(tag: "1.0.0")
        MockedShell.mockGITProject()
    }

    override func tearDown() {
        super.tearDown()
        MockedShell.commandMocks.removeAll()
        Mocker.removeAll()
    }

    /// It should use the GitHub Access Token for setting up URLSession.
    func testAccessTokenConfiguration() throws {
        Mocker.mockPullRequests()
        Mocker.mockForIssueNumber(39)
        MockedShell.mockGITProject(organisation: "WeTransfer", repository: "Diagnostics")

        let token = "username:79B02BE4-38D1-4E3D-9B41-4E0739761512"
        mockGITAuthentication(token)
        try executeCommand("gitbuddy changelog")
        XCTAssertEqual(URLSessionInjector.urlSession.configuration.httpAdditionalHeaders?["Authorization"] as? String, "Basic dXNlcm5hbWU6NzlCMDJCRTQtMzhEMS00RTNELTlCNDEtNEUwNzM5NzYxNTEy")
    }

    /// It should correctly output the changelog.
    func testChangelogOutput() throws {
        Mocker.mockPullRequests()
        Mocker.mockForIssueNumber(39)
        MockedShell.mockGITProject(organisation: "WeTransfer", repository: "Diagnostics")

        let expectedChangelog = """
        - Add charset utf-8 to html head \
        ([#50](https://github.com/WeTransfer/Diagnostics/pull/50)) via [@AvdLee](https://github.com/AvdLee)
        - Get warning for file \'style.css\' after building \
        ([#39](https://github.com/WeTransfer/Diagnostics/issues/39)) via [@AvdLee](https://github.com/AvdLee)
        """

        try AssertExecuteCommand("gitbuddy changelog", expected: expectedChangelog)
    }

    /// It should correctly output the changelog.
    func testSectionedChangelogOutput() throws {
        Mocker.mockPullRequests()
        Mocker.mockIssues()
        Mocker.mockForIssueNumber(39)
        MockedShell.mockGITProject(organisation: "WeTransfer", repository: "Diagnostics")

        let expectedChangelog = """
        **Closed issues:**

        - Include device product names ([#60](https://github.com/WeTransfer/Diagnostics/issues/60))
        - Change the order of reported sessions ([#54](https://github.com/WeTransfer/Diagnostics/issues/54))
        - Encode Logging for HTML so object descriptions are visible ([#51](https://github.com/WeTransfer/Diagnostics/issues/51))
        - Chinese characters display incorrectly in HTML output in Safari ([#48](https://github.com/WeTransfer/Diagnostics/issues/48))
        - Get warning for file 'style.css' after building ([#39](https://github.com/WeTransfer/Diagnostics/issues/39))
        - Crash happening when there is no space left on the device ([#37](https://github.com/WeTransfer/Diagnostics/issues/37))
        - Add support for users without the Apple Mail app ([#36](https://github.com/WeTransfer/Diagnostics/issues/36))
        - Support for Apple Watch App Logs ([#33](https://github.com/WeTransfer/Diagnostics/issues/33))
        - Support different platforms/APIs ([#30](https://github.com/WeTransfer/Diagnostics/issues/30))
        - Strongly typed HTML would be nice ([#6](https://github.com/WeTransfer/Diagnostics/issues/6))

        **Merged pull requests:**

        - Add charset utf-8 to html head ([#50](https://github.com/WeTransfer/Diagnostics/pull/50)) via [@AvdLee](https://github.com/AvdLee)
        """

        try AssertExecuteCommand("gitbuddy changelog --sections", expected: expectedChangelog)
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
        let date = Date().addingTimeInterval(TimeInterval.random(in: 0 ..< 100))
        MockedShell.mockRelease(tag: tag, date: date)

        let producer = try ChangelogProducer(baseBranch: nil)
        XCTAssertEqual(Int(producer.from.timeIntervalSince1970), Int(date.addingTimeInterval(60).timeIntervalSince1970))
    }

    /// It should use a tag passed as argument over the latest tag adding 60 seconds to its creation date..
    func testReleaseUsingTagArgument() throws {
        let expectedTag = "3.0.2"
        let date = Date().addingTimeInterval(TimeInterval.random(in: 0 ..< 100))
        MockedShell.mockRelease(tag: expectedTag, date: date)

        let producer = try ChangelogProducer(since: .tag(tag: expectedTag), baseBranch: nil)
        guard case ChangelogProducer.Since.tag(let tag) = producer.since else {
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
