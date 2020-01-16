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
    private let parser: ArgumentParser
    private let parsedArguments: ArgumentParser.Result
    private let octoKit: Octokit
    private let base: Branch
    private let release: Release

    public init() throws {
        let parser = ArgumentParser(usage: "<options>", overview: "Create a changelog for GitHub repositories")
        self.parser = parser
        let sinceTag = parser.add(option: "--sinceTag", shortName: "-s", kind: String.self, usage: "The tag to use as a base")
        let baseBranch = parser.add(option: "--baseBranch", shortName: "-b", kind: String.self, usage: "The base branch to compare with")
        let verbose = parser.add(option: "--verbose", kind: Bool.self, usage: "Show extra logging for debugging purposes")

        // The first argument is always the executable, drop it
        let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
        parsedArguments = try parser.parse(arguments)

        Log.isVerbose = parsedArguments.get(verbose) ?? false

        let gitHubAPIToken = ProcessInfo.processInfo.environment["DANGER_GITHUB_API_TOKEN"]!
        let config = TokenConfiguration(gitHubAPIToken)
        octoKit = Octokit(config)

        if let tag = parsedArguments.get(sinceTag) {
            release = Release(tag: tag)
        } else {
            release = Release.latest()
        }
        base = parsedArguments.get(baseBranch) ?? "master"
    }

    public func run() throws {
        Log.debug("Latest release is \(release.tag)")

        let project = GITProject.current()
        let pullRequestsFetcher = PullRequestFetcher(octoKit: octoKit, base: base, project: project)
        let pullRequests = try pullRequestsFetcher.fetchAllAfter(release)
        let items = ChangelogItemsFactory(octoKit: octoKit, pullRequests: pullRequests, project: project).items()
        let changelog = ChangelogBuilder(items: items).build()
        
        Log.debug("Generated changelog:\n")
        Log.message(changelog)
    }
}
