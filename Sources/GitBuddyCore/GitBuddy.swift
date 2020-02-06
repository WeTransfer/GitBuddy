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

    enum Error: Swift.Error, CustomDebugStringConvertible {
        case missingAccessToken

        var debugDescription: String { "GitHub Access Token is missing. Add an environment variable: GITBUDDY_ACCESS_TOKEN='username:access_token'" }
    }

    @discardableResult public static func run(arguments: [String] = ProcessInfo.processInfo.arguments, environment: [String: String] = ProcessInfo.processInfo.environment, configuration: URLSessionConfiguration? = nil) throws -> String? {
        let configuration = try configuration ?? sessionConfiguration(using: environment)
        URLSessionInjector.urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        Log.isVerbose = arguments.contains("--verbose")
        var commandRegistry = CommandRegistry(usage: "<commands> <options>",
                                              overview: "Manage your GitHub repositories with ease",
                                              arguments: arguments,
                                              environment: environment)
        try commandRegistry.register(commandType: ChangelogCommand.self)
        try commandRegistry.register(commandType: ReleaseCommand.self)

        addVersionArgument(using: arguments, parser: commandRegistry.parser)

        let output = commandRegistry.run()
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
        guard let gitHubAccessToken = environment["GITBUDDY_ACCESS_TOKEN"] else {
            throw Error.missingAccessToken
        }

        let configuration = URLSessionConfiguration.default
        let token = gitHubAccessToken.data(using: .utf8)!.base64EncodedString()
        configuration.httpAdditionalHeaders = ["Authorization": "Basic \(token)"]
        return configuration
    }
}
