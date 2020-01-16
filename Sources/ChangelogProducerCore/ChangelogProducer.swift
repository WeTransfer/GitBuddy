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

    enum Error: Swift.Error {
        case missingDangerToken
    }

    let octoKit: Octokit
    let base: Branch
    let latestRelease: Release
    let project: GITProject

    public init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        arguments: [String] = ProcessInfo.processInfo.arguments) throws {
        let parser = ArgumentParser(usage: "<options>", overview: "Create a changelog for GitHub repositories")
        let sinceTag = parser.add(option: "--sinceTag", shortName: "-s", kind: String.self, usage: "The tag to use as a base")
        let baseBranch = parser.add(option: "--baseBranch", shortName: "-b", kind: String.self, usage: "The base branch to compare with")
        let verbose = parser.add(option: "--verbose", kind: Bool.self, usage: "Show extra logging for debugging purposes")

        guard let gitHubAPIToken = environment["DANGER_GITHUB_API_TOKEN"] else {
            throw Error.missingDangerToken
        }
        
        let config = TokenConfiguration(gitHubAPIToken)
        octoKit = Octokit(config)

        // The first argument is always the executable, drop it
        let arguments = Array(arguments.dropFirst())
        let parsedArguments = try parser.parse(arguments)

        Log.isVerbose = parsedArguments.get(verbose) ?? false

        if let tag = parsedArguments.get(sinceTag) {
            latestRelease = try Release(tag: tag)
        } else {
            latestRelease = try Release.latest()
        }
        base = parsedArguments.get(baseBranch) ?? "master"
        project = GITProject.current()
    }

    @discardableResult public func run(using session: URLSession = URLSession.shared) throws -> String {
        Log.debug("Latest release is \(latestRelease.tag)")

        let pullRequestsFetcher = PullRequestFetcher(octoKit: octoKit, base: base, project: project)
        let pullRequests = try pullRequestsFetcher.fetchAllAfter(latestRelease, using: session)
        let items = ChangelogItemsFactory(octoKit: octoKit, pullRequests: pullRequests, project: project).items(using: session)
        let changelog = ChangelogBuilder(items: items).build()

        Log.debug("Generated changelog:\n")
        Log.message(changelog)

        return changelog
    }
}
