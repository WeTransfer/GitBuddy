//
//  Mocks.swift
//  ChangelogProducerTests
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import Foundation
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
