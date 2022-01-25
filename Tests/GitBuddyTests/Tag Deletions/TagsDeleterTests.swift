//
//  TagsDeleterTests.swift
//  
//
//  Created by Antoine van der Lee on 25/01/2022.
//

import XCTest
@testable import GitBuddyCore
import Mocker
import OctoKit

final class TagsDeleterTests: XCTestCase {

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

    func testReleaseDeletion() throws {
        Octokit.protocolClasses = []
        mockGITAuthentication("wetransferplatform:c425814d26890ead0ff1984981fc89f017624cb2")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        MockedShell.mockRelease(tag: "1.2.0b935", date: dateFormatter.date(from: "24-12-2021")!)
        MockedShell.mockGITProject(organisation: "WeTransfer", repository: "Mule")
        try executeCommand("gitbuddy tagDeletion --verbose -u 1.2.0b935 -l 1 --prerelease-only --dry-run")
    }
}
