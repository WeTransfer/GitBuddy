//
//  IssuesResolver.swift
//  ChangelogProducerCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit

struct IssuesResolver {
    let octoKit: Octokit
    let project: GITProject
    let input: ChangelogInput

    func resolve(using session: URLSession = URLSession.shared) -> [Issue]? {
        guard let resolvedIssueNumbers = input.body?.resolvingIssues(), !resolvedIssueNumbers.isEmpty else {
            return nil
        }
        return issues(for: resolvedIssueNumbers, using: session)
    }

    private func issues(for issueNumbers: [Int], using session: URLSession) -> [Issue] {
        var issues: [Issue] = []
        let dispatchGroup = DispatchGroup()
        for issueNumber in issueNumbers {
            dispatchGroup.enter()
            octoKit.issue(session, owner: project.organisation, repository: project.repository, number: issueNumber) { response in
                switch response {
                case .success(let issue):
                    issues.append(issue)
                case .failure(let error):
                    print("Fetching issue \(issueNumber) failed with \(error)")
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.wait()
        return issues
    }
}

extension String {

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
