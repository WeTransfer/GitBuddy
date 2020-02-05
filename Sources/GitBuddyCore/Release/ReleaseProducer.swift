//
//  ReleaseProducer.swift
//  GitBuddy
//
//  Created by Antoine van der Lee on 04/02/2020.
//

import Foundation
import OctoKit
import SPMUtility

struct ReleaseCommand: Command {
    let command = "release"
    let description = "Create a new release including a changelog and publish comments on related issues"
    let changelogPath: OptionArgument<String>
    let skipComments: OptionArgument<Bool>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: description)
        changelogPath = subparser.add(option: "--changelogPath", shortName: "-c", kind: String.self, usage: "The path to the Changelog to update it with the latest changes")
        skipComments = subparser.add(option: "--skipComments", shortName: "-s", kind: Bool.self, usage: "Disable commenting on issues and PRs about the new release")
        _ = subparser.add(option: "--verbose", kind: Bool.self, usage: "Show extra logging for debugging purposes")
    }

    @discardableResult func run(using arguments: ArgumentParser.Result) throws -> String {
        let changelogProducer = try ReleaseProducer(changelogPath: arguments.get(changelogPath),
                                                    skipComments: arguments.get(skipComments) ?? false)

        Log.debug("Result of creating the release:\n")
        return try changelogProducer.run().url.absoluteString
    }
}

/// Capable of producing a release, adjusting a Changelog file, and posting comments to released issues/PRs.
final class ReleaseProducer: URLSessionInjectable, ShellInjectable {

    private lazy var octoKit: Octokit = Octokit()
    let changelogURL: Foundation.URL?
    let skipComments: Bool

    init(changelogPath: String?, skipComments: Bool) throws {
        if let changelogPath = changelogPath {
            changelogURL = URL(string: changelogPath)
        } else {
            changelogURL = nil
        }
        self.skipComments = skipComments
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
        for (pullRequest, issues) in changelog.items {
            Log.debug("Marking PR #\(pullRequest.number) as having been released in version #\(release.tag.name)")
            let body = "Congratulations! :tada: This was released as part of [Release \(release.title)](\(release.url)) :rocket:"
            dispatchGroup.enter()
            postComment(issueID: pullRequest.number, project: project, body: body) {
                dispatchGroup.leave()
            }

            issues.forEach { issue in
                Log.debug("Adding a comment to issue #\(issue.number) that pull request #\(pullRequest.number) has been released")
                var body = "The pull request #\(pullRequest.number) that closed this issue was merged and released as part of [Release \(release.title)](\(release.url)) :rocket:\n"
                body += "Please let us know if the functionality works as expected as a reply here. If it does not, please open a new issue. Thanks!"

                dispatchGroup.enter()
                postComment(issueID: issue.number, project: project, body: body) {
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.wait()
    }

    private func postComment(issueID: Int, project: GITProject, body: String, completion: @escaping () -> Void) {
        octoKit.commentIssue(urlSession, owner: project.organisation, repository: project.repository, number: issueID, body: body) { response in
            switch response {
            case .success(let comment):
                Log.debug("Successfully posted comment at: \(comment.htmlURL)")
            case .failure(let error):
                Log.debug("Posting comment for issue #\(issueID) failed: \(error)")
            }
            completion()
        }
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
        octoKit.postRelease(urlSession, owner: project.organisation, repository: project.repository, tagName: tag.name, name: tag.name, body: body, prerelease: false, draft: false) { (response) in
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
