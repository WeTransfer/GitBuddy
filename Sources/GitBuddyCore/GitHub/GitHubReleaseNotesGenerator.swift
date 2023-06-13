//
//  GitHubReleaseNotesGenerator.swift
//  
//
//  Created by Antoine van der Lee on 13/06/2023.
//

import Foundation
import OctoKit

struct GitHubReleaseNotesGenerator {
    let octoKit: Octokit
    let project: GITProject
    let tagName: String
    let targetCommitish: String
    let previousTagName: String

    func generate(using session: URLSession = URLSession.shared) throws -> ReleaseNotes {
        let group = DispatchGroup()
        group.enter()

        var result: Result<ReleaseNotes, Swift.Error>!

        octoKit.generateReleaseNotes(
            session,
            owner: project.organisation,
            repository: project.repository,
            tagName: tagName,
            targetCommitish: targetCommitish,
            previousTagName: previousTagName) { response in
                switch response {
                case .success(let releaseNotes):
                    result = .success(releaseNotes)
                case .failure(let error):
                    result = .failure(OctoKitError(error: error))
                }
                group.leave()
            }

        group.wait()

        return try result.get()
    }
}
