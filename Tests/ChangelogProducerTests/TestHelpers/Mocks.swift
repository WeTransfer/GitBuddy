//
//  Mocks.swift
//  ChangelogProducerTests
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import Foundation
import Mocker
@testable import ChangelogProducerCore

struct MockedShell: ShellExecuting {

    static var commandMocks: [String: String] = [:]

    @discardableResult static func execute(_ command: String) -> String {
        return commandMocks[command] ?? ""
    }

    static func mockRelease(tag: String, date: Date = Date()) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        commandMocks["git tag --sort=committerdate | tail -1"] = tag
        commandMocks["git log -1 --format=%ai \(tag)"] = dateFormatter.string(from: date)
    }

    static func mockGITProject(organisation: String = "WeTransfer", repository: String = "ChangelogProducer") {
        commandMocks["git remote show origin -n | ruby -ne 'puts /^\\s*Fetch.*(:|\\/){1}([^\\/]+\\/[^\\/]+).git/.match($_)[2] rescue nil'"] = "\(organisation)/\(repository)"
    }

}

extension Mocker {
    static func mockPullRequests() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: "2020-01-03")!
        MockedShell.mockRelease(tag: "1.0.0", date: date)
        let pullRequestsURL = URL(string: "https://api.github.com/repos/WeTransfer/Diagnostics/pulls?base=master&direction=desc&sort=updated&state=closed")!
        let pullRequestJSONData = pullRequestsJSON.data(using: .utf8)!
        Mock(url: pullRequestsURL, dataType: .json, statusCode: 200, data: [.get: pullRequestJSONData]).register()
    }
}
