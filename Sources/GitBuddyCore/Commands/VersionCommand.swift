//
//  VersionCommand.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 09/04/2020.
//

import Foundation
import ArgumentParser

struct VersionCommand: ParsableCommand {

    public static let configuration = CommandConfiguration(commandName: "version", abstract: "Prints the current GitBuddy version.")

    public static let version = "2.5.0"

    func run() throws {
        throw CleanExit.message("""
        HL GitBuddy \(Self.version)
        Copyright © 2020 WeTransfer. All rights reserved.
        This Hippocratic License (HL) is an Ethical Source license (https://ethicalsource.dev) derived from the MIT License.
        It's amended to limit the impact of the unethical use of open source software.
        """)
    }

}
