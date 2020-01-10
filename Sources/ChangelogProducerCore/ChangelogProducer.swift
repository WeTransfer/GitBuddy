//
//  ChangelogProducer.swift
//  
//
//  Created by Antoine van der Lee on 10/01/2020.
//

import Foundation
import OctoKit
import SPMUtility

public final class ChangelogProducer {
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    /// Input parameters:
    /// - Target branch, defaults to master
    public func run() throws {
        // The first argument is always the executable, drop it
        let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

        let parser = ArgumentParser(usage: "<options>", overview: "Create a changelog for GitHub repositories")
        let sinceTag: OptionArgument<String> = parser.add(option: "--sinceTag", shortName: "-s", kind: String.self, usage: "The tag to use as a base")
        let baseBranch: OptionArgument<String> = parser.add(option: "--baseBranch", shortName: "-b", kind: String.self, usage: "The base branch to compare with")
        let parsedArguments = try parser.parse(arguments)

        let release: Release = {
            if let tag = parsedArguments.get(sinceTag) {
                return Release(tag: tag)
            }
            return Release.latest()
        }()

        print("Latest release is \(release.tag)")

        let gitHubAPIToken = ProcessInfo.processInfo.environment["DANGER_GITHUB_API_TOKEN"]!
        print("GitHub token is \(gitHubAPIToken)")
        let config = TokenConfiguration(gitHubAPIToken)
        let octoKit = Octokit(config)

        let group = DispatchGroup()
        group.enter()
        let base = parsedArguments.get(baseBranch) ?? "master"
        octoKit.pullRequests(URLSession.shared, owner: "WeTransfer", repository: "Coyote", base: base, state: .Closed, sort: .updated, direction: .desc) { (response) in
            switch response {
            case .success(let pullRequests):
                self.handle(pullRequests, for: release)
            case .failure(let error):
                print(error)
            }
            group.leave()
        }
        group.wait()
    }

    private func handle(_ pullRequests: [PullRequest], for release: Release) {
        let pullRequests = pullRequests.filter { pullRequest -> Bool in
            guard let mergedAt = pullRequest.mergedAt else { return false }
            return mergedAt > release.created
        }

        let changelog = pullRequests.compactMap { $0.title }.joined(separator: "\n")
        print("Generated changelog:\n")
        print(changelog)
    }
}

struct Release {
    let tag: String
    let created: Date

    init(tag: String) {
        let tagCreationDate = Shell.execute("git log -1 --format=%ai \(tag)").filter { !$0.isNewline }
        print("Tag \(tag) is created at \(tagCreationDate)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        self.tag = tag
        self.created = dateFormatter.date(from: tagCreationDate)!
    }

    static func latest() -> Release {
        print("Fetching tags")
        Shell.execute("git fetch --tags")
        let latestTag = Shell.execute("git tag --sort=committerdate | tail -1").filter { !$0.isNewline && !$0.isWhitespace }
        print("Latest tag is \(latestTag)")

        return Release(tag: latestTag)
    }
}
