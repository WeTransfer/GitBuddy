//
//  PullRequestFetcher.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit

typealias Branch = String

struct PullRequestFetcher {
    let octoKit: Octokit
    let baseBranch: Branch
    let project: GITProject

    func fetchAllBetween(_ fromDate: Date, and toDate: Date, using session: URLSession = URLSession.shared) throws -> [PullRequest] {
        let group = DispatchGroup()
        group.enter()

        var result: Result<[PullRequest], Swift.Error>!

        octoKit.pullRequests(
            session,
            owner: project.organisation,
            repository: project.repository,
            base: baseBranch,
            state: .closed,
            sort: .updated,
            direction: .desc,
            perPage: 100
        ) { response in
            switch response {
            case .success(let pullRequests):
                result = .success(pullRequests)
            case .failure(let error):
                result = .failure(OctoKitError(error: error))
            }
            group.leave()
        }
        group.wait()

        return try result.get().filter { pullRequest -> Bool in
            guard let mergedAt = pullRequest.mergedAt else { return false }
            return mergedAt > fromDate && mergedAt < toDate
        }
    }
}
