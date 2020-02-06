//
//  CommandRegistry.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 03/02/2020.
//

import Foundation
import SPMUtility
import Basic

/// Allows to register subcommands that can be run.
struct CommandRegistry {

    private let parser: ArgumentParser
    private var commands: [Command] = []
    private let arguments: [String]
    private let environment: [String: String]

    init(usage: String, overview: String, arguments: [String], environment: [String: String]) {
        parser = ArgumentParser(usage: usage, overview: overview)
        self.arguments = arguments
        self.environment = environment
    }

    mutating func register(commandType: Command.Type) throws {
        let command = try commandType.init(parser: parser)
        commands.append(command)
    }

    private func processArguments() throws -> ArgumentParser.Result {
        // We drop the first argument as this is always the execution path. In our case: "gitbuddy"
        return try parser.parse(Array(arguments.dropFirst()))
    }

    @discardableResult func run() -> String? {
        do {
            let arguments = try processArguments()
            
            guard let subparser = arguments.subparser(parser),
                let command = commands.first(where: { $0.command == subparser }) else {
                parser.printUsage(on: stdoutStream)
                return nil
            }
            return try command.run(using: arguments, environment: environment)
        } catch let error as ArgumentParserError {
            print(error.description)
        } catch let error {
            print(error.localizedDescription)
        }
        return nil
    }

}
