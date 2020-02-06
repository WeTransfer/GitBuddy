//
//  Commenter.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 06/02/2020.
//

import Foundation
import OctoKit

enum Comment {
    case releasedPR(release: Release)
    case releasedIssue(release: Release, pullRequestID: Int)

    var body: String {
        switch self {
        case .releasedPR(let release):
            return "Congratulations! :tada: This was released as part of [Release \(release.title)](\(release.url)) :rocket:"
        case .releasedIssue(let release, let pullRequestID):
            var body = "The pull request #\(pullRequestID) that closed this issue was merged and released as part of [Release \(release.title)](\(release.url)) :rocket:\n"
            body += "Please let us know if the functionality works as expected as a reply here. If it does not, please open a new issue. Thanks!"
            return body
        }
    }
}

/// Responsible for posting comments on issues at GitHub.
struct Commenter {
    static var urlSession: URLSession { URLSessionInjector.urlSession }

    /// Posts a given comment on the issue from the given project.
    /// - Parameters:
    ///   - comment: The comment to post.
    ///   - issueID: The issue ID on which the comment has to be posted.
    ///   - project: The project on which the issue exists. E.g. WeTransfer/Diagnostics.
    ///   - completion: The completion callback which will be called once the comment is placed.
    static func post(_ comment: Comment, on issueID: Int, at project: GITProject, completion: @escaping () -> Void) {
        Octokit().commentIssue(urlSession, owner: project.organisation, repository: project.repository, number: issueID, body: comment.body) { response in
            switch response {
            case .success(let comment):
                Log.debug("Successfully posted comment at: \(comment.htmlURL)")
            case .failure(let error):
                Log.debug("Posting comment for issue #\(issueID) failed: \(error)")
            }
            completion()
        }
    }
}
