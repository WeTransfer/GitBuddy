//
//  XCTestExtensions.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 09/04/2020.
//

import Foundation
import XCTest
@testable import GitBuddyCore

extension XCTest {

    func AssertEqualStringsIgnoringTrailingWhitespace(_ string1: String, _ string2: String, file: StaticString = #file, line: UInt = #line) {
        let lines1 = string1.split(separator: "\n", omittingEmptySubsequences: false)
        let lines2 = string2.split(separator: "\n", omittingEmptySubsequences: false)

        XCTAssertEqual(lines1.count, lines2.count, "Strings have different numbers of lines.", file: file, line: line)
        for (line1, line2) in zip(lines1, lines2) {
            XCTAssertEqual(line1.trimmed(), line2.trimmed(), file: file, line: line)
        }
    }

    /// Executes the command and throws the execution error if any occur.
    /// - Parameters:
    ///   - command: The command to execute. This command can be exactly the same as you would use in the terminal. E.g. "gitbuddy changelog".
    ///   - expected: The expected outcome printed in the console.
    /// - Throws: The error occured while executing the command.
    func AssertExecuteCommand(command: String, expected: String? = nil, file: StaticString = #file, line: UInt = #line) throws {
        let splitCommand = command.split(separator: " ")
        let arguments = splitCommand.dropFirst().map(String.init)

        let gitBuddyCommand = try GitBuddy.parseAsRoot(arguments)

        var output = ""
        Log.pipe = { message in
            output += message
        }

        try gitBuddyCommand.run()

        if let expected = expected {
            AssertEqualStringsIgnoringTrailingWhitespace(expected, output, file: file, line: line)
        }
    }
}

extension Substring {
    func trimmed() -> Substring {
        guard let i = lastIndex(where: { $0 != " "}) else {
            return ""
        }
        return self[...i]
    }
}
