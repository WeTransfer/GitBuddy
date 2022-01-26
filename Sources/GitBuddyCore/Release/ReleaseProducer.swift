//
//  ReleaseProducer.swift
//  GitBuddy
//
//  Created by Antoine van der Lee on 04/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit

/// Capable of producing a release, adjusting a Changelog file, and posting comments to released issues/PRs.
final class ReleaseProducer: URLSessionInjectable, ShellInjectable {

    enum Error: Swift.Error, CustomStringConvertible {
        case changelogTargetDateMissing

        var description: String {
            switch self {
            case .changelogTargetDateMissing:
                return "Tag name is set, but `changelogToTag` is missing"
            }
        }
    }

    private lazy var octoKit: Octokit = Octokit()
    let changelogURL: Foundation.URL?
    let skipComments: Bool
    let isPrerelease: Bool
    let targetCommitish: String?
    let tagName: String?
    let releaseTitle: String?
    let lastReleaseTag: String?
    let changelogToTag: String?
    let baseBranch: String

    init(changelogPath: String?, skipComments: Bool, isPrerelease: Bool, targetCommitish: String? = nil, tagName: String? = nil, releaseTitle: String? = nil, lastReleaseTag: String? = nil, baseBranch: String? = nil, changelogToTag: String? = nil) throws {
        try Octokit.authenticate()

        if let changelogPath = changelogPath {
            changelogURL = URL(string: changelogPath)
        } else {
            changelogURL = nil
        }
        self.skipComments = skipComments
        self.isPrerelease = isPrerelease
        self.targetCommitish = targetCommitish
        self.tagName = tagName
        self.releaseTitle = releaseTitle
        self.lastReleaseTag = lastReleaseTag
        self.changelogToTag = changelogToTag
        self.baseBranch = baseBranch ?? "master"
    }

    @discardableResult public func run(isSectioned: Bool) throws -> Release {
        let changelogToDate = try fetchChangelogToDate()

        /// We're adding 60 seconds to make sure the tag commit itself is included in the changelog as well.
        let adjustedChangelogToDate = changelogToDate.addingTimeInterval(60)

        let changelogSinceTag = lastReleaseTag ?? Self.shell.execute(.previousTag)
        let changelogProducer = try ChangelogProducer(since: .tag(tag: changelogSinceTag), to: adjustedChangelogToDate, baseBranch: baseBranch)
        let changelog = try changelogProducer.run(isSectioned: isSectioned)
        Log.debug("\(changelog)\n")

        let tagName = try tagName ?? Tag.latest().name
        try updateChangelogFile(adding: changelog.description, for: tagName)

        let repositoryName = Self.shell.execute(.repositoryName)
        let project = GITProject.current()
        Log.debug("Creating a release for tag \(tagName) at repository \(repositoryName)")
        let release = try createRelease(using: project, tagName: tagName, targetCommitish: targetCommitish, title: releaseTitle, body: changelog.description)
        postComments(for: changelog, project: project, release: release)

        Log.debug("Result of creating the release:\n")
        return release
    }

    private func fetchChangelogToDate() throws -> Date {
        if tagName != nil {
            /// If a tagname exists, it means we're creating a new tag.
            /// In this case, we need another way to fetch the `to` date for the changelog.
            ///
            /// One option is using the `changelogToTag`:
            if let changelogToTag = changelogToTag {
                return try Tag(name: changelogToTag).created
            } else if let targetCommitishDate = targetCommitishDate() {
                /// We fallback to the target commit date, covering cases in which we create a release
                /// from a certain branch
                return targetCommitishDate
            } else {
                /// Since we were unable to fetch the date
                throw Error.changelogTargetDateMissing
            }
        } else {
            /// This is the scenario of creating a release for an already created tag.
            return try Tag.latest().created
        }
    }

    private func targetCommitishDate() -> Date? {
        guard let targetCommitish = targetCommitish else {
            return nil
        }
        let commitishDate = Self.shell.execute(.commitDate(commitish: targetCommitish))
        return Formatter.gitDateFormatter.date(from: commitishDate)
    }

    private func postComments(for changelog: Changelog, project: GITProject, release: Release) {
        guard !skipComments else {
            Log.debug("Skipping comments")
            return
        }
        let dispatchGroup = DispatchGroup()
        for (pullRequestID, issueIDs) in changelog.itemIdentifiers {
            Log.debug("Marking PR #\(pullRequestID) as having been released in version #\(release.tagName)")
            dispatchGroup.enter()
            Commenter.post(.releasedPR(release: release), on: pullRequestID, at: project) {
                dispatchGroup.leave()
            }

            issueIDs.forEach { issueID in
                Log.debug("Adding a comment to issue #\(issueID) that pull request #\(pullRequestID) has been released")
                dispatchGroup.enter()
                Commenter.post(.releasedIssue(release: release, pullRequestID: pullRequestID), on: issueID, at: project) {
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.wait()
    }

    /// Appends the changelog to the changelog file if the argument is set.
    /// - Parameters:
    ///   - changelog: The changelog to append to the changelog file.
    ///   - tagName: The name of the tag that is used as the title for the newly added section.
    private func updateChangelogFile(adding changelog: String, for tagName: String) throws {
        guard let changelogURL = changelogURL else {
            Log.debug("Skipping changelog file updating")
            return
        }

        let currentContent = try String(contentsOfFile: changelogURL.path)
        let newContent = """
        ### \(tagName)
        \(changelog)\n
        \(currentContent)
        """

        let handle = try FileHandle(forWritingTo: changelogURL)
        handle.write(Data(newContent.utf8))
        handle.closeFile()
    }

    private func createRelease(using project: GITProject, tagName: String, targetCommitish: String?, title: String?, body: String) throws -> Release {
        let group = DispatchGroup()
        group.enter()

        let releaseTitle = title ?? tagName
        Log.debug("""
        \nCreating a new release:
            owner:           \(project.organisation)
            repo:            \(project.repository)
            tagName:         \(tagName)
            targetCommitish: \(targetCommitish ?? "default")
            prerelease:      \(isPrerelease)
            draft:           false
            title:           \(releaseTitle)
            body:
            \(body)\n
        """)

        var result: Result<Foundation.URL, Swift.Error>!
        octoKit.postRelease(urlSession, owner: project.organisation, repository: project.repository, tagName: tagName, targetCommitish: targetCommitish, name: releaseTitle, body: body, prerelease: isPrerelease, draft: false) { (response) in
            switch response {
            case .success(let release):
                result = .success(release.htmlURL)
            case .failure(let error):
                result = .failure(error)
            }
            group.leave()
        }
        group.wait()
        let releaseURL = try result.get()
        return Release(tagName: tagName, url: releaseURL, title: releaseTitle, changelog: body)
    }
}
