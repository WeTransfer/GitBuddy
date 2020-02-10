//
//  GitBuddyTests.swift
//  GitBuddyTests
//
//  Created by Antoine van der Lee on 04/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import XCTest
@testable import GitBuddyCore

final class GitBuddyTests: XCTestCase {

    /// It should use the GitHub Access Token for setting up URLSession.
    func testAccessTokenConfiguration() throws {
        let token = "79B02BE4-38D1-4E3D-9B41-4E0739761512"
        try GitBuddy.run(arguments: [], environment: ["GITBUDDY_ACCESS_TOKEN": token])
        XCTAssertEqual(URLSessionInjector.urlSession.configuration.httpAdditionalHeaders?["Authorization"] as? String, "Basic NzlCMDJCRTQtMzhEMS00RTNELTlCNDEtNEUwNzM5NzYxNTEy")
    }

    /// It should throw an error if the GitHub access token was not set.
    func testMissingAccessToken() {
        do {
            _ = try GitBuddy.run()
        } catch {
            XCTAssertEqual(error as? GitBuddy.Error, .missingAccessToken)
        }
    }

    /// It should enable verbose logging.
    func testVerboseLogging() {
        XCTAssertFalse(Log.isVerbose)
        _ = try? GitBuddy.run(arguments: ["GitBuddy", "--verbose"], environment: ["GITBUDDY_ACCESS_TOKEN": UUID().uuidString])
        XCTAssertTrue(Log.isVerbose)
    }
}
