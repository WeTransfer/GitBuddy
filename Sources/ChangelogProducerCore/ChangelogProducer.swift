//
//  ChangelogProducer.swift
//  
//
//  Created by Antoine van der Lee on 10/01/2020.
//

import Foundation
import OctoKit
import SPMUtility

struct Log {
    static var isVerbose: Bool = false

    static func debug(_ message: Any) {
        guard isVerbose else { return }
        print(message)
    }

    static func message(_ message: Any) {
        print(message)
    }
}

public final class ChangelogProducer {
    private let parser: ArgumentParser
    private let sinceTag: OptionArgument<String>
    private let baseBranch: OptionArgument<String>
    private let parsedArguments: ArgumentParser.Result

    public init() throws {
        let parser = ArgumentParser(usage: "<options>", overview: "Create a changelog for GitHub repositories")
        self.parser = parser
        self.sinceTag = parser.add(option: "--sinceTag", shortName: "-s", kind: String.self, usage: "The tag to use as a base")
        self.baseBranch = parser.add(option: "--baseBranch", shortName: "-b", kind: String.self, usage: "The base branch to compare with")
        let verbose = parser.add(option: "--verbose", kind: Bool.self, usage: "Show extra logging for debugging purposes")

        // The first argument is always the executable, drop it
        let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
        parsedArguments = try parser.parse(arguments)

        Log.isVerbose = parsedArguments.get(verbose) ?? false
    }

    public func run() throws {
        let release = fetchRelease()
        Log.debug("Latest release is \(release.tag)")

        let gitHubAPIToken = ProcessInfo.processInfo.environment["DANGER_GITHUB_API_TOKEN"]!
        let project = GITProject.current()

        let config = TokenConfiguration(gitHubAPIToken)
        let octoKit = Octokit(config)

        let group = DispatchGroup()
        group.enter()
        let base = parsedArguments.get(baseBranch) ?? "master"
        octoKit.pullRequests(URLSession.shared, owner: project.organisation, repository: project.repository, base: base, state: .Closed, sort: .updated, direction: .desc) { (response) in
            switch response {
            case .success(let pullRequests):
                self.handle(pullRequests, for: release)
            case .failure(let error):
                Log.debug(error)
            }
            group.leave()
        }
        group.wait()
    }



    private func fetchRelease() -> Release {
        if let tag = parsedArguments.get(sinceTag) {
            return Release(tag: tag)
        }
        return Release.latest()
    }

    private func handle(_ pullRequests: [PullRequest], for release: Release) {
        let pullRequests = pullRequests.filter { pullRequest -> Bool in
            guard let mergedAt = pullRequest.mergedAt else { return false }
            return mergedAt > release.created
        }

        let changelog = pullRequests
            .compactMap { $0.title }
            .filter { !$0.lowercased().contains("#trivial") }
            .map { "- \($0)" }
            .joined(separator: "\n")
        Log.debug("Generated changelog:\n")
        Log.message(changelog)
    }
}

struct Release {
    let tag: String
    let created: Date

    init(tag: String) {
        let tagCreationDate = Shell.execute("git log -1 --format=%ai \(tag)").filter { !$0.isNewline }
        Log.debug("Tag \(tag) is created at \(tagCreationDate)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        self.tag = tag
        self.created = dateFormatter.date(from: tagCreationDate)!
    }

    static func latest() -> Release {
        Log.debug("Fetching tags")
        Shell.execute("git fetch --tags")
        let latestTag = Shell.execute("git tag --sort=committerdate | tail -1").filter { !$0.isNewline && !$0.isWhitespace }
        Log.debug("Latest tag is \(latestTag)")

        return Release(tag: latestTag)
    }
}

struct GITProject {
    let organisation: String
    let repository: String

    static func current() -> GITProject {
        /// E.g. WeTransfer/Coyote
        let projectInfo = Shell.execute("git remote show origin -n | ruby -ne 'puts /^\\s*Fetch.*(:|\\/){1}([^\\/]+\\/[^\\/]+).git/.match($_)[2] rescue nil'")
            .split(separator: "/")
            .map { String($0).filter { !$0.isNewline } }

        return GITProject(organisation: String(projectInfo[0]), repository: String(projectInfo[1]))
    }
}
