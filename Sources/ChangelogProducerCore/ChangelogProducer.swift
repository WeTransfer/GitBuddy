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

    public func run() throws {
        print("Hello world")
    }
}
