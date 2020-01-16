//
//  PullRequestFetcher.swift
//  ChangelogProducerCore
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import Foundation
import OctoKit

typealias Branch = String

struct PullRequestFetcher {

    let octoKit: Octokit
    let base: Branch
    let project: GITProject

    func fetchAllAfter(_ release: Release, using session: URLSession = URLSession.shared) throws -> [PullRequest] {
        let group = DispatchGroup()
        group.enter()

        var result: Result<[PullRequest], Swift.Error>!

        octoKit.pullRequests(session, owner: project.organisation, repository: project.repository, base: base, state: .Closed, sort: .updated, direction: .desc) { (response) in
            switch response {
            case .success(let pullRequests):
                result = .success(pullRequests)
            case .failure(let error):
                result = .failure(error)
            }
            group.leave()
        }
        group.wait()

        return try result.get().filter { pullRequest -> Bool in
            guard let mergedAt = pullRequest.mergedAt else { return false }
            return mergedAt > release.created
        }
    }

}
