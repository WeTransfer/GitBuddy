//
//  StringExtensions.swift
//  
//
//  Created by Antoine van der Lee on 10/01/2020.
//

import Foundation

extension String {

    /// Gets the Pull Request ID from a `String` based on #{id} format.
    /// - returns: An ordered list of found Pull Request identifiers.
    func pullRequestIDs() -> [Int] {
        return []
    }

    /// Extracts the resolved issue from a Pull Request body.
    func resolvingIssue() -> Int? {
        return nil
    }
}
