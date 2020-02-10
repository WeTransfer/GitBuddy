//
//  Mocks.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import Mocker
import OctoKit
@testable import GitBuddyCore

struct MockedShell: ShellExecuting {

    static var commandMocks: [String: String] = [:]

    @discardableResult static func execute(_ command: ShellCommand) -> String {
        return commandMocks[command.rawValue] ?? ""
    }

    static func mock(_ command: ShellCommand, value: String) {
        commandMocks[command.rawValue] = value
    }

    static func mockRelease(tag: String, date: Date = Date()) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        commandMocks[ShellCommand.latestTag.rawValue] = tag
        commandMocks[ShellCommand.tagCreationDate(tag: tag).rawValue] = dateFormatter.string(from: date)
    }

    static func mockGITProject(organisation: String = "WeTransfer", repository: String = "GitBuddy") {
        commandMocks[ShellCommand.repositoryName.rawValue] = "\(organisation)/\(repository)"
    }
}

class MockChangelogInput: ChangelogInput {
    let number: Int
    let title: String?
    let body: String?
    let username: String?
    let htmlURL: Foundation.URL?

    init(number: Int = 0, title: String? = nil, body: String? = nil, username: String? = nil, htmlURL: URL? = nil) {
        self.number = number
        self.title = title
        self.body = body
        self.username = username
        self.htmlURL = htmlURL
    }
}

final class MockedPullRequest: MockChangelogInput, ChangelogPullRequest { }
final class MockedIssue: MockChangelogInput, ChangelogIssue { }

extension Mocker {
    @discardableResult static func mockPullRequests(baseBranch: String = "master") -> Mock {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: "2020-01-03")!
        MockedShell.mockRelease(tag: "1.0.0", date: date)

        var urlComponents = URLComponents(url: URL(string: "https://api.github.com/repos/WeTransfer/Diagnostics/pulls")!, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "base", value: baseBranch),
            URLQueryItem(name: "direction", value: "desc"),
            URLQueryItem(name: "sort", value: "updated"),
            URLQueryItem(name: "state", value: "closed")
        ]

        let pullRequestJSONData = PullRequestsJSON.data(using: .utf8)!
        let mock = Mock(url: urlComponents.url!, dataType: .json, statusCode: 200, data: [.get: pullRequestJSONData])
        mock.register()
        return mock
    }

    static func mockForIssueNumber(_ issueNumber: Int) {
        let urlComponents = URLComponents(string: "https://api.github.com/repos/WeTransfer/Diagnostics/issues/\(issueNumber)")!
        let issueJSONData = IssueJSON.data(using: .utf8)!
        Mock(url: urlComponents.url!, dataType: .json, statusCode: 200, data: [.get: issueJSONData]).register()
    }

    @discardableResult static func mockRelease() -> Mock {
        let releaseJSONData = ReleaseJSON.data(using: .utf8)!
        let mock = Mock(url: URL(string: "https://api.github.com/repos/WeTransfer/Diagnostics/releases")!, dataType: .json, statusCode: 201, data: [.post: releaseJSONData])
        mock.register()
        return mock
    }

    static func mockForCommentingOn(issueNumber: Int) -> Mock {
        let urlComponents = URLComponents(string: "https://api.github.com/repos/WeTransfer/Diagnostics/issues/\(issueNumber)/comments")!
        let commentJSONData = CommentJSON.data(using: .utf8)!
        return Mock(url: urlComponents.url!, dataType: .json, statusCode: 201, data: [.post: commentJSONData])
    }
}

extension Data {
    func mapJSON<T: Decodable>(to type: T.Type) -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Time.rfc3339DateFormatter)
        return try! decoder.decode(type, from: self)
    }
}
