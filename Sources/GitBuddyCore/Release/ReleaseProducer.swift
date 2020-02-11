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
    let isPrerelease: OptionArgument<Bool>
    let targetCommitish: OptionArgument<String>
    let tagName: OptionArgument<String>
    let releaseTitle: OptionArgument<String>
    let lastReleaseTag: OptionArgument<String>
    let baseBranch: OptionArgument<String>

    init(subparser: ArgumentParser) {
        changelogPath = subparser.add(option: "--changelog-path", shortName: "-c", kind: String.self, usage: "The path to the Changelog to update it with the latest changes")
        skipComments = subparser.add(option: "--skip-comments", shortName: "-s", kind: Bool.self, usage: "Disable commenting on issues and PRs about the new release")
        isPrerelease = subparser.add(option: "--use-pre-release", shortName: "-p", kind: Bool.self, usage: "Create the release as a pre-release")
        targetCommitish = subparser.add(option: "--target-commitish", shortName: "-t", kind: String.self, usage: "Specifies the commitish value that determines where the Git tag is created from. Can be any branch or commit SHA. Unused if the Git tag already exists. Default: the repository's default branch (usually master).")
        tagName = subparser.add(option: "--tag-name", shortName: "-n", kind: String.self, usage: "The name of the tag. Default: takes the last created tag to publish as a GitHub release.")
        releaseTitle = subparser.add(option: "--release-title", shortName: "-r", kind: String.self, usage: "The title of the release. Default: uses the tag name.")
        lastReleaseTag = subparser.add(option: "--last-release-tag", shortName: "-l", kind: String.self, usage: "The last release tag to use as a base for the changelog creation. Default: previous tag")
        baseBranch = subparser.add(option: "--base-branch", shortName: "-b", kind: String.self, usage: "The base branch to compare with for generating the changelog. Defaults to master.")
    }

    @discardableResult func run(using arguments: ArgumentParser.Result) throws -> String {
        let releaseProducer = try ReleaseProducer(changelogPath: arguments.get(changelogPath),
                                                  skipComments: arguments.get(skipComments) ?? false,
                                                  isPrerelease: arguments.get(isPrerelease) ?? false,
                                                  targetCommitish: arguments.get(targetCommitish),
                                                  tagName: arguments.get(tagName),
                                                  releaseTitle: arguments.get(releaseTitle),
                                                  lastReleaseTag: arguments.get(lastReleaseTag),
                                                  baseBranch: arguments.get(baseBranch))
        return try releaseProducer.run().url.absoluteString
    }
}

/// Capable of producing a release, adjusting a Changelog file, and posting comments to released issues/PRs.
final class ReleaseProducer: URLSessionInjectable, ShellInjectable {

    private lazy var octoKit: Octokit = Octokit()
    let changelogURL: Foundation.URL?
    let skipComments: Bool
    let isPrerelease: Bool
    let targetCommitish: String?
    let tagName: String?
    let releaseTitle: String?
    let lastReleaseTag: String?
    let baseBranch: String
    
    init(changelogPath: String?, skipComments: Bool, isPrerelease: Bool, targetCommitish: String? = nil, tagName: String? = nil, releaseTitle: String? = nil, lastReleaseTag: String? = nil, baseBranch: String? = nil) throws {
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
        self.baseBranch = baseBranch ?? "master"
    }

    @discardableResult public func run() throws -> Release {
        let releasedTag = try tagName.map { try Tag(name: $0, created: Date()) } ?? Tag.latest()
        let previousTag = lastReleaseTag ?? Self.shell.execute(.previousTag)

        /// We're adding 60 seconds to make sure the tag commit itself is included in the changelog as well.
        let toDate = releasedTag.created.addingTimeInterval(60)
        let changelogProducer = try ChangelogProducer(since: .tag(tag: previousTag), to: toDate, baseBranch: baseBranch)
        let changelog = try changelogProducer.run()
        Log.debug("\(changelog)\n")

        try updateChangelogFile(adding: changelog.description, for: releasedTag)

        let repositoryName = Self.shell.execute(.repositoryName)
        let project = GITProject.current()
        Log.debug("Creating a release for tag \(releasedTag.name) at repository \(repositoryName)")
        let release = try createRelease(using: project, tag: releasedTag, targetCommitish: targetCommitish, title: releaseTitle, body: changelog.description)
        postComments(for: changelog, project: project, release: release)

        Log.debug("Result of creating the release:\n")
        return release
    }

    private func postComments(for changelog: Changelog, project: GITProject, release: Release) {
        guard !skipComments else {
            Log.debug("Skipping comments")
            return
        }
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
        guard let changelogURL = changelogURL else {
            Log.debug("Skipping changelog file updating")
            return
        }

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

    private func createRelease(using project: GITProject, tag: Tag, targetCommitish: String?, title: String?, body: String) throws -> Release {
        let group = DispatchGroup()
        group.enter()

        Log.debug("""
        \nCreating a new release:
            owner:           \(project.organisation)
            repo:            \(project.repository)
            tagName:         \(tag.name)
            targetCommitish: \(targetCommitish ?? "default")
            prerelease:      \(isPrerelease)
            draft:           false
            title:           \(title ?? tag.name)
            body:
            \(body)\n
        """)

        var result: Result<Foundation.URL, Swift.Error>!
        octoKit.postRelease(urlSession, owner: project.organisation, repository: project.repository, tagName: tag.name, targetCommitish: targetCommitish, name: title ?? tag.name, body: body, prerelease: isPrerelease, draft: false) { (response) in
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
