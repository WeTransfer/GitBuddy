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
        - Add charset utf-8 to html head ([#50](https://github.com/WeTransfer/Diagnostics/pull/50)) via @AvdLee
        - Get warning for file \'style.css\' after building ([#39](https://github.com/WeTransfer/Diagnostics/issues/39)) via @AvdLee

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
        let mockExpectation = expectation(description: "Mocks should be called")
        mockExpectation.isInverted = true
        var mock = Mocker.mockForCommentingOn(issueNumber: 39)
        mock.completion = {
            mockExpectation.fulfill()
        }
        mock.register()

        _ = try GitBuddy.run(arguments: ["GitBuddy", "release", "-s"], configuration: configuration)
        wait(for: [mockExpectation], timeout: 0.3)
    }
}
