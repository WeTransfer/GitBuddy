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
    let verbose: OptionArgument<Bool>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: description)
        changelogPath = subparser.add(option: "--changelogPath", shortName: "-c", kind: String.self, usage: "The path to the Changelog to update it with the latest changes")
        skipComments = subparser.add(option: "--skipComments", shortName: "-s", kind: Bool.self, usage: "Disable commenting on issues and PRs about the new release")
        verbose = subparser.add(option: "--verbose", kind: Bool.self, usage: "Show extra logging for debugging purposes")
    }

    @discardableResult func run(using arguments: ArgumentParser.Result) throws -> String {
        let changelogProducer = try ReleaseProducer(changelogPath: arguments.get(changelogPath),
                                                    skipComments: arguments.get(skipComments) ?? false,
                                                    verbose: arguments.get(verbose) ?? false)
        return try changelogProducer.run()
    }
}

/// Capable of producing a release, adjusting a Changelog file, and posting comments to released issues/PRs.
final class ReleaseProducer: URLSessionInjectable, ShellInjectable {

    private lazy var octoKit: Octokit = Octokit()
    let changelogPath: String?
    let skipComments: Bool

    init(changelogPath: String?, skipComments: Bool, verbose: Bool) throws {
        // The first argument is always the executable, drop it
        Log.isVerbose = verbose
        self.changelogPath = changelogPath
        self.skipComments = skipComments
    }

    @discardableResult public func run() throws -> String {
        Log.debug("Fetching tags..")
        Self.shell.execute("git fetch --tags origin master --no-recurse-submodules -q")

        let releasedTag = Self.shell.execute("git describe --abbrev=0 --tags `git rev-list --tags --max-count=1 --no-walk`").trimmingCharacters(in: .whitespacesAndNewlines)
        let previousTag = Self.shell.execute("git describe --abbrev=0 --tags `git rev-list --tags --skip=1 --max-count=1 --no-walk`").trimmingCharacters(in: .whitespacesAndNewlines)

        Log.debug("Creating a changelog between tag \(previousTag) and \(releasedTag)")
        let changelogProducer = try ChangelogProducer(sinceTag: previousTag, baseBranch: "master", verbose: Log.isVerbose)
        let changelog = try changelogProducer.run()

        let commitish = Self.shell.execute("git rev-parse HEAD")
        let repositoryName = Self.shell.execute("git remote show origin -n | ruby -ne 'puts /^\\s*Fetch.*(:|\\/){1}([^\\/]+\\/[^\\/]+).git/.match($_)[2] rescue nil'").trimmingCharacters(in: .whitespacesAndNewlines)

        Log.debug("Creating a release for tag \(releasedTag) at repository \(repositoryName) using commitish \(commitish)")

        let owner = String(repositoryName.split(separator: "/").first!)
        let repository = String(repositoryName.split(separator: "/").last!)

        let group = DispatchGroup()
        group.enter()

        var result: String!
        octoKit.postRelease(urlSession, owner: owner, repository: repository, tagName: releasedTag, targetCommitish: nil, name: releasedTag, body: changelog, prerelease: false, draft: false) { (response) in
            switch response {
            case .success(let release):
                result = "Created release at \(release.htmlURL)"
            case .failure(let error):
                result = "Releasing failed: \(error)"
            }
            group.leave()
        }
        group.wait()
        return result
    }
}
