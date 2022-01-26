//
//  Shell.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

enum ShellCommand {
    case fetchTags
    case latestTag
    case previousTag
    case repositoryName
    case tagCreationDate(tag: String)
    case commitDate(commitish: String)

    var rawValue: String {
        switch self {
        case .fetchTags:
            return "git fetch --tags origin --no-recurse-submodules -q"
        case .latestTag:
            return "git describe --abbrev=0 --tags `git rev-list --tags --max-count=1 --no-walk`"
        case .previousTag:
            return "git describe --abbrev=0 --tags `git rev-list --tags --skip=1 --max-count=1 --no-walk`"
        case .repositoryName:
            return "git remote show origin -n | ruby -ne 'puts /^\\s*Fetch.*(:|\\/){1}([^\\/]+\\/[^\\/]+).git/.match($_)[2] rescue nil'"
        case .tagCreationDate(let tag):
            return "git log -1 --format=%ai \(tag)"
        case .commitDate(let commitish):
            return "git show -s --format=%ai \(commitish)"
        }
    }
}

extension Process {
    func shell(_ command: ShellCommand) -> String {
        launchPath = "/bin/bash"
        arguments = ["-c", command.rawValue]

        let outputPipe = Pipe()
        standardOutput = outputPipe
        launch()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let outputData = String(data: data, encoding: String.Encoding.utf8) else { return "" }

        return outputData.reduce("") { (result, value) in
            return result + String(value)
        }.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

protocol ShellExecuting {
    @discardableResult static func execute(_ command: ShellCommand) -> String
}

private enum Shell: ShellExecuting {
    @discardableResult static func execute(_ command: ShellCommand) -> String {
        return Process().shell(command)
    }
}

/// Adds a `shell` property which defaults to `Shell.self`.
protocol ShellInjectable { }

extension ShellInjectable {
    static var shell: ShellExecuting.Type { ShellInjector.shell }
}

enum ShellInjector {
    static var shell: ShellExecuting.Type = Shell.self
}
