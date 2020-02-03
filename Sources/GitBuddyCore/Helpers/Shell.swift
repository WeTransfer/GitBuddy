//
//  Shell.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

extension Process {
    public func shell(command: String) -> String {
        launchPath = "/bin/bash"
        arguments = ["-c", command]

        let outputPipe = Pipe()
        standardOutput = outputPipe
        launch()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let outputData = String(data: data, encoding: String.Encoding.utf8) else { return "" }

        return outputData.reduce("") { (result, value) in
            return result + String(value)
        }
    }
}

protocol ShellExecuting {
    @discardableResult static func execute(_ command: String) -> String
}

private enum Shell: ShellExecuting {
    @discardableResult static func execute(_ command: String) -> String {
        return Process().shell(command: command)
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
