//
//  GitBuddy.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 03/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import SPMUtility

/// Entry class of GitBuddy that registers commands and handles execution.
public enum GitBuddy {

    public static let version = "2.0.0"

    @discardableResult public static func run(arguments: [String] = ProcessInfo.processInfo.arguments, environment: [String: String] = ProcessInfo.processInfo.environment, configuration: URLSessionConfiguration? = nil) throws -> String? {
        Log.isVerbose = arguments.contains("--verbose")

        let configuration = try configuration ?? sessionConfiguration(using: environment)
        URLSessionInjector.urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        var commandRegistry = CommandRegistry(usage: "<commands> <options>",
                                              overview: "Manage your GitHub repositories with ease",
                                              arguments: arguments,
                                              environment: environment)
        try commandRegistry.register(commandType: ChangelogCommand.self)
        try commandRegistry.register(commandType: ReleaseCommand.self)

        addVersionArgument(using: arguments, parser: commandRegistry.parser)

        let output = try commandRegistry.run()
        Log.message(output)
        return output
    }

    private static func addVersionArgument(using arguments: [String], parser: ArgumentParser) {
        guard !arguments.contains("--version") else {
            print("""
            HL GitBuddy \(Self.version)
            Copyright © 2020 WeTransfer. All rights reserved.
            This Hippocratic License (HL) is an Ethical Source license (https://ethicalsource.dev) derived from the MIT License.
            It's amended to limit the impact of the unethical use of open source software.
            """)
            exit(0)
        }
        _ = parser.add(option: "--version", kind: String.self, usage: "Prints the current GitBuddy version")
    }

    private static func sessionConfiguration(using environment: [String: String]) throws -> URLSessionConfiguration {
        let token = try Token(environment: environment)
        Log.debug("Token is \(token)")
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization": "Basic \(token.base64Encoded)"]
        return configuration
    }
}
