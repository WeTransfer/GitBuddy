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
        let subparser = parser.add(subparser: commandType.command, overview: commandType.description)
        let command = try commandType.init(subparser: subparser)
        subparser.addHelpArgument()
        subparser.addVerboseArgument()
        commands.append(command)
    }

    private func processArguments() throws -> ArgumentParser.Result {
        return try parser.parse(Array(arguments.dropFirst()))
    }

    @discardableResult func run() -> String {
        do {
            let arguments = try processArguments()
            
            guard let subparser = arguments.subparser(parser),
                let command = commands.first(where: { type(of: $0).command == subparser }) else {
                parser.printUsage(on: stdoutStream)
                return ""
            }
            return try command.run(using: arguments)
        } catch let error as ArgumentParserError {
            return error.description
        } catch let error {
            return error.localizedDescription
        }
    }

}

private extension ArgumentParser {
    func addHelpArgument() {
        _ = add(option: "--help", kind: Bool.self, usage: "Display available options")
    }

    func addVerboseArgument() {
        _ = add(option: "--verbose", kind: Bool.self, usage: "Show extra logging for debugging purposes")
    }
}
