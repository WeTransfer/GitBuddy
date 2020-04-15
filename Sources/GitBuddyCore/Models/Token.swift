//
//  Token.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

struct Token: CustomStringConvertible {
    enum Error: Swift.Error, LocalizedError {
        case missingAccessToken
        case invalidAccessToken

        var errorDescription: String? { debugDescription }
        var debugDescription: String {
            switch self {
            case .missingAccessToken:
                return "GitHub Access Token is missing. Add an environment variable: GITBUDDY_ACCESS_TOKEN='username:access_token'"
            case .invalidAccessToken:
                return "Access token is found but invalid. Correct format: <username>:<access_token>"
            }
        }
    }

    let username: String
    let accessToken: String

    var base64Encoded: String {
        "\(username):\(accessToken)".data(using: .utf8)!.base64EncodedString()
    }

    var description: String {
        "\(username):\(accessToken.prefix(5))..."
    }

    init(environment: [String: String]) throws {
        guard let gitHubAccessToken = environment["GITBUDDY_ACCESS_TOKEN"] else {
            throw Error.missingAccessToken
        }
        let tokenParts = gitHubAccessToken.split(separator: ":")
        guard tokenParts.count == 2, let username = tokenParts.first, let accessToken = tokenParts.last else {
            throw Error.invalidAccessToken
        }

        self.username = String(username)
        self.accessToken = String(accessToken)
    }

}
