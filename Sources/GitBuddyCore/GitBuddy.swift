//
//  GitBuddy.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 03/02/2020.
//

import Foundation
import SPMUtility

/// Entry class of GitBuddy that registers commands and handles execution.
public final class GitBuddy {

    public static func run() throws {
        var commandRegistry = try CommandRegistry(usage: "<commands> <options>", overview: "Manage your GitHub repositories with ease")
        commandRegistry.register(command: ChangelogProducer.self)
        try commandRegistry.run()
    }
}
