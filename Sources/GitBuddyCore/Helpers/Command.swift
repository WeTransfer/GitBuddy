//
//  Command.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 03/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import SPMUtility

/// Defines a command that can be executed.
protocol Command {
    /// The name of the command.
    static var command: String { get }

    /// The command description explaining what it does.
    static var description: String { get }

    /// Creates a new instance of this `Command`.
    /// - Parameter subparser: The subparser that is being used for this execution.
    init(subparser: ArgumentParser) throws

    /// Runs the command with the given arguments and environment.
    /// - Parameters:
    ///   - arguments: The arguments that are parsed upon execution.
    @discardableResult func run(using arguments: ArgumentParser.Result) throws -> String
}
