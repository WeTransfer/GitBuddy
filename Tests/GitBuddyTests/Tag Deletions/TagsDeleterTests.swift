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
        Mocker.mockListReleases()
        MockedShell.mockGITProject(organisation: "WeTransfer", repository: "Diagnostics")
    }

    override func tearDown() {
        super.tearDown()
        MockedShell.commandMocks.removeAll()
        Mocker.removeAll()
    }

    func testDeletingUpUntilTagName() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateMatchingTagInMockedJSON = dateFormatter.date(from: "26-06-2013")!
        MockedShell.mockRelease(tag: "2.0.0", date: dateMatchingTagInMockedJSON)

        let expectedTags = ["v1.0.0", "v1.0.1", "v1.0.2", "v1.0.3"]
        for (index, tagName) in expectedTags.enumerated() {
            Mocker.mockDeletingRelease(id: index)
            Mocker.mockDeletingReference(tagName: tagName)
        }

        let output = try executeCommand("gitbuddy tagDeletion -u 2.0.0 -l 100")
        XCTAssertEqual(output, "Deleted tags: [\"\(expectedTags.joined(separator: "\", \""))\"]")
    }

    func testDeletingLimit() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateMatchingTagInMockedJSON = dateFormatter.date(from: "26-06-2013")!
        MockedShell.mockRelease(tag: "2.0.0", date: dateMatchingTagInMockedJSON)

        Mocker.mockDeletingRelease(id: 1)
        Mocker.mockDeletingReference(tagName: "v1.0.3")

        let output = try executeCommand("gitbuddy tagDeletion -u 2.0.0 -l 1")
        XCTAssertEqual(output, "Deleted tags: [\"v1.0.3\"]")
    }

    func testDeletingPrereleaseOnly() throws {
        MockedShell.mockRelease(tag: "2.0.0", date: Date())

        Mocker.mockDeletingRelease(id: 1)
        Mocker.mockDeletingReference(tagName: "v1.0.3")

        let output = try executeCommand("gitbuddy tagDeletion -u 2.0.0 -l 1 --prerelease-only")
        XCTAssertEqual(output, "Deleted tags: [\"v1.0.3\"]")
    }

    func testDeletingUpUntilLastTag() throws {
        MockedShell.mockRelease(tag: "2.0.0", date: Date())

        MockedShell.mock(.previousTag, value: "2.0.0")
        Mocker.mockDeletingRelease(id: 1)
        Mocker.mockDeletingReference(tagName: "v1.0.3")

        let output = try executeCommand("gitbuddy tagDeletion -l 1 --prerelease-only")
        XCTAssertEqual(output, "Deleted tags: [\"v1.0.3\"]")
    }
}
