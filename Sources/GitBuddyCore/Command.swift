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

    /// The command description explaining what it does.
    var description: String { get }

    /// Creates a new instance of this `Command`.
    /// - Parameter parser: The main parser that is being used for execution.
    init(parser: ArgumentParser) throws

    /// Runs the command with the given arguments and environment.
    /// - Parameters:
    ///   - arguments: The arguments that are parsed upon execution.
    ///   - environment: The available environment variables.
    @discardableResult func run(using arguments: ArgumentParser.Result, environment: [String: String]) throws -> String
}
