//
//  CommenterTests.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 09/04/2020.
//

import XCTest
@testable import GitBuddyCore
import Mocker

final class CommenterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        URLSessionInjector.urlSession = URLSession(configuration: configuration)
        ShellInjector.shell = MockedShell.self
    }

    override func tearDown() {
        super.tearDown()
        URLSessionInjector.urlSession = URLSession.shared
    }

    /// It should add a watermark to the comments.
    func testWatermark() throws {
        Mocker.mockPullRequests()
        let latestTag = try Tag.latest()
        let release = Release(tag: latestTag, url: URL(string: "https://www.fakegithub.com")!, title: "Release title")
        let project = GITProject(organisation: "WeTransfer", repository: "GitBuddy")

        let mockExpectation = expectation(description: "Mock should be called")
        var mock = Mock(url: URL(string: "https://api.github.com/repos/WeTransfer/GitBuddy/issues/1/comments")!, dataType: .json, statusCode: 200, data: [.post: Data()])
        mock.onRequest = { _, postBodyArguments in
            let body = postBodyArguments?["body"] as? String
            XCTAssertTrue(body?.contains(Commenter.watermark) == true)
            mockExpectation.fulfill()
        }
        mock.register()

        let commentExpectation = expectation(description: "Comment should post")
        Commenter.post(.releasedPR(release: release), on: 1, at: project) {
            commentExpectation.fulfill()
        }
        wait(for: [mockExpectation, commentExpectation], timeout: 10.0, enforceOrder: true)
    }
}
