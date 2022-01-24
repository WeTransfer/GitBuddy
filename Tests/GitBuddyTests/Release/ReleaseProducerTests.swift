//
//  ReleaseProducerTests.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 05/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import XCTest
@testable import GitBuddyCore
import Mocker
import OctoKit

final class ReleaseProducerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Octokit.protocolClasses = [MockingURLProtocol.self]
        mockGITAuthentication()
        ShellInjector.shell = MockedShell.self
        Mocker.mockPullRequests()
        Mocker.mockIssues()
        Mocker.mockForIssueNumber(39)
        Mocker.mockRelease()
        MockedShell.mockRelease(tag: "1.0.1")
        MockedShell.mock(.previousTag, value: "1.0.0")
        MockedShell.mockGITProject(organisation: "WeTransfer", repository: "Diagnostics")
    }

    override func tearDown() {
        super.tearDown()
        MockedShell.commandMocks.removeAll()
        Mocker.removeAll()
    }

    /// It should use the GitHub Access Token for setting up URLSession.
    func testAccessTokenConfiguration() throws {
        let token = "username:79B02BE4-38D1-4E3D-9B41-4E0739761512"
        mockGITAuthentication(token)
        try executeCommand("gitbuddy release -s")
        XCTAssertEqual(URLSessionInjector.urlSession.configuration.httpAdditionalHeaders?["Authorization"] as? String, "Basic dXNlcm5hbWU6NzlCMDJCRTQtMzhEMS00RTNELTlCNDEtNEUwNzM5NzYxNTEy")
    }

    /// It should correctly output the release URL.
    func testReleaseOutputURL() throws {
        try AssertExecuteCommand("gitbuddy release -s", expected: "https://github.com/WeTransfer/ChangelogProducer/releases/tag/1.0.1")
    }

    func testReleaseOutputJSON() throws {
        let output = try executeCommand("gitbuddy release -s --json")
        XCTAssertTrue(output.contains("{\"title\":\"1.0.1\",\"tagName\":\"1.0.1\",\"url\":\"https:\\/\\/github.com\\/WeTransfer\\/ChangelogProducer\\/releases\\/tag\\/1.0.1\""))
    }

    /// It should set the parameters correctly.
    func testPostBodyArguments() throws {
        let mockExpectation = expectation(description: "Mocks should be called")
        var mock = Mocker.mockRelease()
        mock.onRequest = { _, parameters in
            guard let parameters = try? XCTUnwrap(parameters) else { return }
            XCTAssertEqual(parameters["prerelease"] as? Bool, false)
            XCTAssertEqual(parameters["draft"] as? Bool, false)
            XCTAssertEqual(parameters["tag_name"] as? String, "1.0.1")
            XCTAssertEqual(parameters["name"] as? String, "1.0.1")
            XCTAssertEqual(parameters["body"] as? String, """
            - Add charset utf-8 to html head \
            ([#50](https://github.com/WeTransfer/Diagnostics/pull/50)) via [@AvdLee](https://github.com/AvdLee)
            - Get warning for file 'style.css' after building \
            ([#39](https://github.com/WeTransfer/Diagnostics/issues/39)) via [@AvdLee](https://github.com/AvdLee)
            """)
            mockExpectation.fulfill()
        }
        mock.register()

        try executeCommand("gitbuddy release -s")
        wait(for: [mockExpectation], timeout: 0.3)
    }

    /// It should update the changelog file if the argument is set.
    func testChangelogUpdating() throws {
        let existingChangelog = """
        ### 1.0.0
        - Initial release
        """
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("Changelog.md")
        XCTAssertTrue(FileManager.default.createFile(atPath: tempFileURL.path, contents: Data(existingChangelog.utf8), attributes: nil))
        try executeCommand("gitbuddy release -s -c \(tempFileURL.path)")
        let updatedChangelogContents = try String(contentsOfFile: tempFileURL.path)

        XCTAssertEqual(updatedChangelogContents, """
        ### 1.0.1
        - Add charset utf-8 to html head \
        ([#50](https://github.com/WeTransfer/Diagnostics/pull/50)) via [@AvdLee](https://github.com/AvdLee)
        - Get warning for file \'style.css\' after building \
        ([#39](https://github.com/WeTransfer/Diagnostics/issues/39)) via [@AvdLee](https://github.com/AvdLee)

        \(existingChangelog)
        """)
    }

    func testSectionedChangelogUpdating() throws {
        let existingChangelog = """
        ### 1.0.0
        - Initial release
        """
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("Changelog.md")
        XCTAssertTrue(FileManager.default.createFile(atPath: tempFileURL.path, contents: Data(existingChangelog.utf8), attributes: nil))
        try executeCommand("gitbuddy release --sections -s -c \(tempFileURL.path)")

        let updatedChangelogContents = try String(contentsOfFile: tempFileURL.path)

        XCTAssertEqual(updatedChangelogContents, """
        ### 1.0.1
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

        \(existingChangelog)
        """)
    }

    /// It should comment on related pull requests and issues.
    func testPullRequestIssueCommenting() throws {
        let mocksExpectations = expectation(description: "Mocks should be called")
        mocksExpectations.expectedFulfillmentCount = 3
        let mocks = [
            Mocker.mockForCommentingOn(issueNumber: 39),
            Mocker.mockForCommentingOn(issueNumber: 49),
            Mocker.mockForCommentingOn(issueNumber: 50)
        ]
        mocks.forEach { mock in
            var mock = mock
            mock.completion = {
                mocksExpectations.fulfill()
            }
            mock.register()
        }
        try executeCommand("gitbuddy release")
        wait(for: [mocksExpectations], timeout: 2.0)
    }

    /// It should not post comments if --skipComments is passed as an argument.
    func testSkippingComments() throws {
        let mockExpectation = expectation(description: "Mock should not be called")
        mockExpectation.isInverted = true
        var mock = Mocker.mockForCommentingOn(issueNumber: 39)
        mock.completion = {
            mockExpectation.fulfill()
        }
        mock.register()

        try executeCommand("gitbuddy release -s")
        wait(for: [mockExpectation], timeout: 0.3)
    }

    /// It should use the prerelease setting.
    func testPrerelease() throws {
        let mockExpectation = expectation(description: "Mocks should be called")
        var mock = Mocker.mockRelease()
        mock.onRequest = { _, parameters in
            guard let parameters = try? XCTUnwrap(parameters) else { return }
            XCTAssertTrue(parameters["prerelease"] as? Bool == true)
            mockExpectation.fulfill()
        }
        mock.register()

        try executeCommand("gitbuddy release -s -p")
        wait(for: [mockExpectation], timeout: 0.3)
    }

    /// It should use the target commitish setting.
    func testTargetCommitish() throws {
        let mockExpectation = expectation(description: "Mocks should be called")
        var mock = Mocker.mockRelease()
        mock.onRequest = { _, parameters in
            guard let parameters = try? XCTUnwrap(parameters) else { return }
            XCTAssertEqual(parameters["target_commitish"] as? String, "develop")
            mockExpectation.fulfill()
        }
        mock.register()

        try executeCommand("gitbuddy release -s -t develop")
        wait(for: [mockExpectation], timeout: 0.3)
    }

    /// It should use the tag name setting.
    func testTagName() throws {
        let mockExpectation = expectation(description: "Mocks should be called")
        let tagName = "3.0.0b1233"
        let changelogToTag = "3.0.0b1232"
        MockedShell.mockRelease(tag: changelogToTag)
        var mock = Mocker.mockRelease()
        mock.onRequest = { _, parameters in
            guard let parameters = try? XCTUnwrap(parameters) else { return }
            XCTAssertEqual(parameters["tag_name"] as? String, tagName)
            mockExpectation.fulfill()
        }
        mock.register()

        try executeCommand("gitbuddy release --changelogToTag \(changelogToTag) -s -n \(tagName)")
        wait(for: [mockExpectation], timeout: 0.3)
    }

    func testThrowsMissingTargetDateError() {
        XCTAssertThrowsError(try executeCommand("gitbuddy release -s -n 3.0.0"), "Missing target date error should be thrown") { error in
            XCTAssertEqual(error as? ReleaseProducer.Error, .changelogTargetDateMissing)
        }
    }

    /// It should not contain changes that are merged into the target branch after the creation date of the tag we're using.
    func testIncludedChangesForUsedTagName() throws {
        let existingChangelog = """
        ### 1.0.0
        - Initial release
        """
        let tagName = "2.0.0b1233"
        let changelogToTag = "2.0.0b1232"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: "2020-01-05")!
        MockedShell.mockRelease(tag: changelogToTag, date: date)

        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("Changelog.md")
        XCTAssertTrue(FileManager.default.createFile(atPath: tempFileURL.path, contents: Data(existingChangelog.utf8), attributes: nil))

        try executeCommand("gitbuddy release --changelogToTag \(changelogToTag) -s -n \(tagName) -c \(tempFileURL.path)")

        let updatedChangelogContents = try String(contentsOfFile: tempFileURL.path)

        // Merged at: 2020-01-06 - Add charset utf-8 to html head
        // Closed at: 2020-01-03 - Get warning for file
        // Setting the tag date to 2020-01-05 should remove the Add charset

        XCTAssertEqual(updatedChangelogContents, """
        ### 2.0.0b1233
        - Get warning for file \'style.css\' after building \
        ([#39](https://github.com/WeTransfer/Diagnostics/issues/39)) via [@AvdLee](https://github.com/AvdLee)

        \(existingChangelog)
        """)
    }

    /// It should use the release title setting.
    func testReleaseTitle() throws {
        let mockExpectation = expectation(description: "Mocks should be called")
        let title = UUID().uuidString
        var mock = Mocker.mockRelease()
        mock.onRequest = { _, parameters in
            guard let parameters = try? XCTUnwrap(parameters) else { return }
            XCTAssertEqual(parameters["name"] as? String, title)
            mockExpectation.fulfill()
        }
        mock.register()

        try executeCommand("gitbuddy release -s -r \(title)")
        wait(for: [mockExpectation], timeout: 0.3)
    }

    /// It should use the changelog settings.
    func testChangelogSettings() throws {
        let lastReleaseTag = "2.0.1"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: "2020-01-03")!
        MockedShell.mockRelease(tag: lastReleaseTag, date: date)

        let baseBranch = UUID().uuidString
        Mocker.mockPullRequests(baseBranch: baseBranch)

        try executeCommand("gitbuddy release -s -l \(lastReleaseTag) -b \(baseBranch)")
    }
}
