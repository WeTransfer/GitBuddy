//
//  GitBuddy.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 03/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import ArgumentParser

/// Entry class of GitBuddy that registers commands and handles execution.
public struct GitBuddy: ParsableCommand {
    public static let version = "3.0.1"

    public static let configuration = CommandConfiguration(
        commandName: "gitbuddy",
        abstract: "Manage your GitHub repositories with ease",
        version: Self.version,
        subcommands: [ChangelogCommand.self, ReleaseCommand.self]
    )

    public init() { }
}
