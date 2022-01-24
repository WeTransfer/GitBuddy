//
//  GitBuddyCommandTests.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 04/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import XCTest
@testable import GitBuddyCore

final class GitBuddyCommandTests: XCTestCase {

    /// It should throw an error if the GitHub access token was not set.
    func testMissingAccessToken() {
        do {
            try executeCommand("gitbuddy changelog")
        } catch {
            XCTAssertEqual(error as? Token.Error, .missingAccessToken)
        }
    }

    /// It should throw an error if the GitHub access token was invalid.
    func testInvalidAccessToken() {
        do {
            mockGITAuthentication(UUID().uuidString)
            try executeCommand("gitbuddy changelog")
        } catch {
            XCTAssertEqual(error as? Token.Error, .invalidAccessToken)
        }
    }

    /// It should only print partly the access token.
    func testDebugPrintAccessToken() throws {
        let token = try Token(environment: ["GITBUDDY_ACCESS_TOKEN": "username:79B02BE4-38D1-4E3D-9B41-4E0739761512"])
        XCTAssertEqual(token.description, "username:79B02...")
    }
}
