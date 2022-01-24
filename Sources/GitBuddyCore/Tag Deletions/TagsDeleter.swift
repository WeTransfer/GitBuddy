import Foundation
import OctoKit

final class TagsDeleter: URLSessionInjectable, ShellInjectable {

    private lazy var octoKit: Octokit = Octokit()
    let upUntilTagName: String?
    let limit: Int
    let prereleaseOnly: Bool
    let dryRun: Bool

    init(upUntilTagName: String? = nil, limit: Int, prereleaseOnly: Bool, dryRun: Bool) throws {
        try Octokit.authenticate()

        self.upUntilTagName = upUntilTagName
        self.limit = limit
        self.prereleaseOnly = prereleaseOnly
        self.dryRun = dryRun
    }

    @discardableResult public func run() throws -> [String] {
        let upUntilTag = try upUntilTagName.map { try Tag(name: $0) } ?? Tag.latest()
        Log.debug("Deleting up to \(limit) tags before \(upUntilTag.name) (Dry run: \(dryRun.description))")

        let currentProject = GITProject.current()
        let releases = try fetchReleases(project: currentProject, upUntil: upUntilTag.created)

        guard !releases.isEmpty else {
            return []
        }
        deleteReleases(releases, project: currentProject)

        return []
    }

    private func fetchReleases(project: GITProject, upUntil: Date) throws -> [OctoKit.Release] {
        let group = DispatchGroup()
        group.enter()

        var result: Result<[OctoKit.Release], Swift.Error>!
        octoKit.listReleases(urlSession, owner: project.organisation, repository: project.repository, perPage: 100) { response in
            result = response
            group.leave()
        }
        group.wait()

        let releases = try result.get()
        Log.debug("Fetched releases: \(releases.map { $0.tagName }.joined(separator: ", "))")

        return releases.filter({ release in
            guard !prereleaseOnly || release.prerelease else {
                return false
            }
            return release.createdAt < upUntil
        }).suffix(limit)
    }

    private func deleteReleases(_ releases: [OctoKit.Release], project: GITProject) {
        let tagsToDelete = releases.map { $0.tagName }
        Log.debug("Deleting tags: \(tagsToDelete.joined(separator: ", "))")

        let group = DispatchGroup()

        for release in releases {
            group.enter()
            Log.debug("Deleting \(release.tagName) with id \(release.id) url: \(release.htmlURL)")
            guard !dryRun else {
                group.leave()
                return
            }

            octoKit.deleteRelease(owner: project.organisation, repository: project.repository, releaseId: release.id) { error in
                defer { group.leave() }
                guard let error = error else {
                    Log.debug("Successfully deleted \(release.tagName)")
                    return
                }
                Log.debug("Deletion of \(release.tagName) failed: \(error)")
            }
        }
        group.wait()
    }
}
