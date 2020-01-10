//
//  ChangelogProducer.swift
//  
//
//  Created by Antoine van der Lee on 10/01/2020.
//

import Foundation

public final class ChangelogProducer {
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    /// Input parameters:
    /// - Target branch, defaults to master
    public func run() throws {
        print("Hello world")
        /// Fetch last release from GitHub
        /// Fetch PRs after last released tag creation date
    }
}
