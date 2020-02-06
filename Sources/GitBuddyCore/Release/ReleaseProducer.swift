//
//  ReleaseProducer.swift
//  GitBuddy
//
//  Created by Antoine van der Lee on 04/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation
import OctoKit
import SPMUtility

struct ReleaseCommand: Command {
    static let command = "release"
    static let description = "Create a new release including a changelog and publish comments on related issues"
    let changelogPath: OptionArgument<String>
    let skipComments: OptionArgument<Bool>
    let isPrelease: OptionArgument<Bool>

    init(subparser: ArgumentParser) {
        changelogPath = subparser.add(option: "--changelog-path", shortName: "-c", kind: String.self, usage: "The path to the Changelog to update it with the latest changes")
        skipComments = subparser.add(option: "--skip-comments", shortName: "-s", kind: Bool.self, usage: "Disable commenting on issues and PRs about the new release")
        isPrelease = subparser.add(option: "--use-pre-release", shortName: "-p", kind: Bool.self, usage: "Create the release as a pre-release")
    }

    @discardableResult func run(using arguments: ArgumentParser.Result) throws -> String {
        let changelogProducer = try ReleaseProducer(changelogPath: arguments.get(changelogPath),
                                                    skipComments: arguments.get(skipComments) ?? false,
                                                    isPrelease: arguments.get(isPrelease) ?? false)

        Log.debug("Result of creating the release:\n")
        return try changelogProducer.run().url.absoluteString
    }
}

/// Capable of producing a release, adjusting a Changelog file, and posting comments to released issues/PRs.
final class ReleaseProducer: URLSessionInjectable, ShellInjectable {

    private lazy var octoKit: Octokit = Octokit()
    let changelogURL: Foundation.URL?
    let skipComments: Bool
    let isPrelease: Bool

    init(changelogPath: String?, skipComments: Bool, isPrelease: Bool) throws {
        if let changelogPath = changelogPath {
            changelogURL = URL(string: changelogPath)
        } else {
            changelogURL = nil
        }
        self.skipComments = skipComments
        self.isPrelease = isPrelease
    }

    @discardableResult public func run() throws -> Release {
        let releasedTag = try Tag.latest()
        let previousTag = Self.shell.execute(.previousTag)

        Log.debug("Creating a changelog between tag \(previousTag) and \(releasedTag.name)")
        let changelog = try ChangelogProducer(sinceTag: previousTag, baseBranch: "master").run()

        try updateChangelogFile(adding: changelog.description, for: releasedTag)

        let repositoryName = Self.shell.execute(.repositoryName)
        let project = GITProject.current()
        Log.debug("Creating a release for tag \(releasedTag.name) at repository \(repositoryName)")
        let release = try createRelease(using: project, tag: releasedTag, body: changelog.description)
        postComments(for: changelog, project: project, release: release)
        return release
    }

    private func postComments(for changelog: Changelog, project: GITProject, release: Release) {
        guard !skipComments else { return }
        let dispatchGroup = DispatchGroup()
        for (pullRequestID, issueIDs) in changelog.itemIdentifiers {
            Log.debug("Marking PR #\(pullRequestID) as having been released in version #\(release.tag.name)")
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
    ///   - tag: The tag that is used as the title for the newly added section.
    private func updateChangelogFile(adding changelog: String, for tag: Tag) throws {
        guard let changelogURL = changelogURL else { return }

        let currentContent = try String(contentsOfFile: changelogURL.path)
        let newContent = """
        ### \(tag.name)
        \(changelog)\n
        \(currentContent)
        """

        let handle = try FileHandle(forWritingTo: changelogURL)
        handle.write(Data(newContent.utf8))
        handle.closeFile()
    }

    private func createRelease(using project: GITProject, tag: Tag, body: String) throws -> Release {
        let group = DispatchGroup()
        group.enter()

        var result: Result<Foundation.URL, Swift.Error>!
        octoKit.postRelease(urlSession, owner: project.organisation, repository: project.repository, tagName: tag.name, name: tag.name, body: body, prerelease: isPrelease, draft: false) { (response) in
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
        return Release(tag: tag, url: releaseURL, title: tag.name)
    }
}
