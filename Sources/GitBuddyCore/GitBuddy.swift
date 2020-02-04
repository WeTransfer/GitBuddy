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

    @discardableResult public static func run(arguments: [String] = ProcessInfo.processInfo.arguments, environment: [String: String] = ProcessInfo.processInfo.environment) throws -> String? {
        var commandRegistry = CommandRegistry(usage: "<commands> <options>",
                                              overview: "Manage your GitHub repositories with ease",
                                              arguments: arguments,
                                              environment: environment)
        try commandRegistry.register(commandType: ChangelogCommand.self)
        return commandRegistry.run()
    }
}
