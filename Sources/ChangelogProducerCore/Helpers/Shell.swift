//
//  Shell.swift
//  ChangelogProducerCore
//
//  Created by Antoine van der Lee on 10/01/2020.
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

enum Shell {
    @discardableResult static func execute(_ command: String) -> String {
        return Process().shell(command: command)
    }
}
