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
    
    /// Extracts the resolved issues from a Pull Request body.
    func resolvingIssues() -> [Int] {
        var resolvedIssues = Set<Int>()
        
        let splits = split(separator: "#")
        
        let issueClosingKeywords = [
            "close ",
            "closes ",
            "closed ",
            "fix ",
            "fixes ",
            "fixed ",
            "resolve ",
            "resolves ",
            "resolved "
        ]
        
        for (index, split) in splits.enumerated() {
            let lowerCaseSplit = split.lowercased()
            
            for keyword in issueClosingKeywords {
                if lowerCaseSplit.hasSuffix(keyword) {
                    guard index + 1 <= splits.count - 1 else { break }
                    let nextSplit = splits[index + 1]
                    
                    let numberPrefixString = nextSplit.prefix { (character) -> Bool in
                        return character.isNumber
                    }
                    
                    if !numberPrefixString.isEmpty, let numberPrefix = Int(numberPrefixString.description) {
                        resolvedIssues.insert(numberPrefix)
                        break
                    } else {
                        continue
                    }
                }
            }
        }
                        
        return Array(resolvedIssues)
    }
}
