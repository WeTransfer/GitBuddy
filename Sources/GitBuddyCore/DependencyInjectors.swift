//
//  DependencyInjectors.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 03/02/2020.
//

import Foundation

/// Adds a `urlSession` property which defaults to `URLSession.shared`.
protocol URLSessionInjectable { }

extension URLSessionInjectable {
    var urlSession: URLSession { return URLSessionInjector.urlSession }
}

enum URLSessionInjector {
    static var urlSession: URLSession = URLSession.shared
}
