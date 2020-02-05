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
        return try changelogProducer.run()
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

    @discardableResult public func run() throws -> String {
        let releasedTag = try Release.latest().tag
        let previousTag = Self.shell.execute(.previousTag)

        Log.debug("Creating a changelog between tag \(previousTag) and \(releasedTag)")
        let changelog = try ChangelogProducer(sinceTag: previousTag, baseBranch: "master").run()

        try updateChangelogFile(adding: changelog, for: releasedTag)

        let repositoryName = Self.shell.execute(.repositoryName)
        let project = GITProject.current()
        Log.debug("Creating a release for tag \(releasedTag) at repository \(repositoryName)")
        return postRelease(using: project, tag: releasedTag, body: changelog)
    }

    /// Appends the changelog to the changelog file if the argument is set.
    /// - Parameters:
    ///   - changelog: The changelog to append to the changelog file.
    ///   - tag: The tag that is used as the title for the newly added section.
    private func updateChangelogFile(adding changelog: String, for tag: String) throws {
        guard let changelogURL = changelogURL else { return }

        let currentContent = try String(contentsOfFile: changelogURL.path)
        let newContent = """
        ### \(tag)
        \(changelog)\n
        \(currentContent)
        """

        let handle = try FileHandle(forWritingTo: changelogURL)
        handle.write(Data(newContent.utf8))
        handle.closeFile()
    }

    private func postRelease(using project: GITProject, tag: String, body: String) -> String {
        let group = DispatchGroup()
        group.enter()

        var result: String!
        octoKit.postRelease(urlSession, owner: project.organisation, repository: project.repository, tagName: tag, name: tag, body: body, prerelease: false, draft: false) { (response) in
            switch response {
            case .success(let release):
                Log.debug("Created release at:\n")
                result = release.htmlURL.absoluteString
            case .failure(let error):
                Log.debug("Releasing failed:\n")
                result = "\(error)"
            }
            group.leave()
        }
        group.wait()
        return result
    }
}
