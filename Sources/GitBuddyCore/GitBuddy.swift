//
//  GitBuddy.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 03/02/2020.
//

import Foundation
import SPMUtility

/// Entry class of GitBuddy that registers commands and handles execution.
public enum GitBuddy {

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
        let output = commandRegistry.run()
        Log.message(output)
        return output
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
