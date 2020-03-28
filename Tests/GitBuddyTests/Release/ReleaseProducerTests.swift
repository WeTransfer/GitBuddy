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
    }

    /// It should correctly output the release URL.
    func testReleaseOutput() throws {
        let releaseURL = try GitBuddy.run(arguments: ["GitBuddy", "release", "-s"], configuration: configuration)
        XCTAssertEqual(releaseURL, "https://github.com/WeTransfer/ChangelogProducer/releases/tag/1.0.1")
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

        _ = try GitBuddy.run(arguments: ["GitBuddy", "release", "-s"], configuration: configuration)
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
        try GitBuddy.run(arguments: ["GitBuddy", "release", "-s", "-c", tempFileURL.path], configuration: configuration)
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
        try GitBuddy.run(arguments: ["GitBuddy", "release", "--sections", "-s", "-c", tempFileURL.path], configuration: configuration)
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
        _ = try GitBuddy.run(arguments: ["GitBuddy", "release"], configuration: configuration)
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

        _ = try GitBuddy.run(arguments: ["GitBuddy", "release", "-s"], configuration: configuration)
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

        _ = try GitBuddy.run(arguments: ["GitBuddy", "release", "-s", "-p"], configuration: configuration)
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

        _ = try GitBuddy.run(arguments: ["GitBuddy", "release", "-s", "-t", "develop"], configuration: configuration)
        wait(for: [mockExpectation], timeout: 0.3)
    }

    /// It should use the tag name setting.
    func testTagName() throws {
        let mockExpectation = expectation(description: "Mocks should be called")
        let tagName = UUID().uuidString
        var mock = Mocker.mockRelease()
        mock.onRequest = { _, parameters in
            guard let parameters = try? XCTUnwrap(parameters) else { return }
            XCTAssertEqual(parameters["tag_name"] as? String, tagName)
            mockExpectation.fulfill()
        }
        mock.register()

        _ = try GitBuddy.run(arguments: ["GitBuddy", "release", "-s", "-n", tagName], configuration: configuration)
        wait(for: [mockExpectation], timeout: 0.3)
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

        _ = try GitBuddy.run(arguments: ["GitBuddy", "release", "-s", "-r", title], configuration: configuration)
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

        _ = try GitBuddy.run(arguments: ["GitBuddy", "release", "-s", "-l", lastReleaseTag, "-b", baseBranch, "--verbose"], configuration: configuration)
    }
}
