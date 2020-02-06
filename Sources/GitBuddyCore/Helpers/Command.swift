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
    static var command: String { get }

    /// The command description explaining what it does.
    static var description: String { get }

    init(subparser: ArgumentParser) throws
    @discardableResult func run(using arguments: ArgumentParser.Result) throws -> String
}
