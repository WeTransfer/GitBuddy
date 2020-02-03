//
//  Command.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 03/02/2020.
//

import Foundation
import SPMUtility

/// Defines a command that can be executed.
protocol Command {
    /// The name of the command.
    var command: String { get }

    /// The overview explaining what the command is about.
    var overview: String { get }

    init(parser: ArgumentParser)
    @discardableResult func run(arguments: ArgumentParser.Result, environment: [String: String]) throws -> String
}
