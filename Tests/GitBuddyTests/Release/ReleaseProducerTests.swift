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

    /// It should correctly output the release URL.
    func testReleaseOutput() throws {
        Mocker.mockPullRequests()
        Mocker.mockForIssueNumber(39)
        Mocker.mockRelease()
        MockedShell.mockRelease(tag: "1.0.1")
        MockedShell.mock(.previousTag, value: "1.0.0")
        MockedShell.mockGITProject(organisation: "WeTransfer", repository: "Diagnostics")
        let releaseURL = try GitBuddy.run(arguments: ["GitBuddy", "release"], configuration: configuration)
        XCTAssertEqual(releaseURL, "https://github.com/WeTransfer/ChangelogProducer/releases/tag/1.0.1")
    }
}
