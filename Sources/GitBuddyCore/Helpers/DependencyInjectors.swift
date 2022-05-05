//
//  DependencyInjectors.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 03/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

/// Adds a `urlSession` property which defaults to `URLSession.shared`.
protocol URLSessionInjectable {}

extension URLSessionInjectable {
    var urlSession: URLSession { return URLSessionInjector.urlSession }
}

enum URLSessionInjector {
    /// Will be setup using the configuration inside the GitBuddy.run method
    static var urlSession: URLSession!
}
