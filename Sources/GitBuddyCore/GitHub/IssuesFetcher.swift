//
//  IssuesFetcher.swift
//
//
//  Created by Max Desiatov on 26/03/2020.
//

import Foundation
import OctoKit

struct IssuesFetcher {

    let octoKit: Octokit
    let project: GITProject

    func fetchAllBetween(_ fromDate: Date, and toDate: Date, using session: URLSession = URLSession.shared) throws -> [Issue] {
        let group = DispatchGroup()
        group.enter()

        var result: Result<[Issue], Swift.Error>!

        octoKit.issues(session, owner: project.organisation, repository: project.repository, state: .Closed) { (response) in
            switch response {
            case .success(let issues):
                result = .success(issues)
            case .failure(let error):
                result = .failure(error)
            }
            group.leave()
        }
        group.wait()

        return try result.get().filter { issue -> Bool in
            guard
                // It looks like OctoKit.swift doesn't support `pull_request` property that helps in
                // distinguishing between issues and pull requests, as the issues endpoint returns both.
                // See https://developer.github.com/v3/issues/ for more details.
                issue.htmlURL?.pathComponents.contains("issues") ?? false,
                let closedAt = issue.closedAt
            else { return false }
            return closedAt > fromDate && closedAt < toDate
        }
    }

}
