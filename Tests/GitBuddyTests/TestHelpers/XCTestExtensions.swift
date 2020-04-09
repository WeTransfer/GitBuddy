//
//  XCTestExtensions.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 09/04/2020.
//

import Foundation
import XCTest
import ArgumentParser
@testable import GitBuddyCore

public func AssertEqualStringsIgnoringTrailingWhitespace(_ string1: String, _ string2: String, file: StaticString = #file, line: UInt = #line) {
    let lines1 = string1.split(separator: "\n", omittingEmptySubsequences: false)
    let lines2 = string2.split(separator: "\n", omittingEmptySubsequences: false)

    XCTAssertEqual(lines1.count, lines2.count, "Strings have different numbers of lines.", file: file, line: line)
    for (line1, line2) in zip(lines1, lines2) {
        XCTAssertEqual(line1.trimmed(), line2.trimmed(), file: file, line: line)
    }
}

extension XCTest {
    public var debugURL: URL {
        let bundleURL = Bundle(for: type(of: self)).bundleURL

        return bundleURL.lastPathComponent.hasSuffix("xctest") ? bundleURL.deletingLastPathComponent() : bundleURL
    }

    public func AssertExecuteCommand(command: String, expected: String? = nil, file: StaticString = #file, line: UInt = #line) throws {
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

extension String {
    public func trimmingLines() -> String {
        return self
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmed() }
            .joined(separator: "\n")
    }
}
