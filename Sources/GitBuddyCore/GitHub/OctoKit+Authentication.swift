//
//  URLSessionConfiguration+Authentication.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 09/04/2020.
//

import Foundation
import OctoKit

extension Octokit {

    static var protocolClasses: [AnyClass]?
    static var environment: [String: String] = ProcessInfo.processInfo.environment
    
    static func authenticate() throws {
        let token = try Token(environment: environment)
        Log.debug("Token is \(token)")
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization": "Basic \(token.base64Encoded)"]
        configuration.protocolClasses = protocolClasses ?? configuration.protocolClasses
        URLSessionInjector.urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }
}
