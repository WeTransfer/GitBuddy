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

    init(usage: String, overview: String) throws {
        parser = ArgumentParser(usage: usage, overview: overview)
    }

    mutating func register(command: Command.Type) {
        commands.append(command.init(parser: parser))
    }

    private func processArguments() throws -> ArgumentParser.Result {
        let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
        return try parser.parse(arguments)
    }

    func run() throws {
        do {
            let arguments = try processArguments()
            
            guard let subparser = arguments.subparser(parser),
                let command = commands.first(where: { $0.command == subparser }) else {
                parser.printUsage(on: stdoutStream)
                return
            }

            try command.run(arguments: arguments, environment: ProcessInfo.processInfo.environment)
        } catch let error as ArgumentParserError {
            print(error.description)
        } catch let error {
            print(error.localizedDescription)
        }
    }

}
