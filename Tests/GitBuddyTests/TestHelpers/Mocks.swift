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

struct MockChangelogInput: ChangelogInput {
    let number: Int?
    let title: String?
    let body: String?
    let username: String?
    let htmlURL: Foundation.URL?

    init(number: Int? = nil, title: String? = nil, body: String? = nil, username: String? = nil, htmlURL: URL? = nil) {
        self.number = number
        self.title = title
        self.body = body
        self.username = username
        self.htmlURL = htmlURL
    }
}

extension Mocker {
    static func mockPullRequests() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: "2020-01-03")!
        MockedShell.mockRelease(tag: "1.0.0", date: date)

        var urlComponents = URLComponents(url: URL(string: "https://api.github.com/repos/WeTransfer/Diagnostics/pulls?base=master&direction=desc&sort=updated&state=closed")!, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "base", value: "master"),
            URLQueryItem(name: "direction", value: "desc"),
            URLQueryItem(name: "sort", value: "updated"),
            URLQueryItem(name: "state", value: "closed")
        ]

        let pullRequestJSONData = PullRequestsJSON.data(using: .utf8)!
        Mock(url: urlComponents.url!, dataType: .json, statusCode: 200, data: [.get: pullRequestJSONData]).register()
    }

    static func mockForIssueNumber(_ issueNumber: Int) {
        let urlComponents = URLComponents(string: "https://api.github.com/repos/WeTransfer/Diagnostics/issues/\(issueNumber)")!
        let issueJSONData = IssueJSON.data(using: .utf8)!
        Mock(url: urlComponents.url!, dataType: .json, statusCode: 200, data: [.get: issueJSONData]).register()
    }
}

extension Data {
    func mapJSON<T: Decodable>(to type: T.Type) -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Time.rfc3339DateFormatter)
        return try! decoder.decode(type, from: self)
    }
}
