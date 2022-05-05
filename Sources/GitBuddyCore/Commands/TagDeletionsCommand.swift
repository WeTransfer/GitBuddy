import ArgumentParser
import Foundation

struct TagDeletionsCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "tagDeletion",
        abstract: "Delete a batch of tags based on given predicates."
    )

    @Option(name: .shortAndLong, help: "The date of this tag will be used as a limit. Defaults to the latest tag.")
    private var upUntilTag: String?

    @Option(name: .shortAndLong, help: "The limit of tags to delete in this batch. Defaults to 50")
    private var limit: Int = 50

    @Flag(name: .long, help: "Delete pre releases only")
    private var prereleaseOnly: Bool = false

    @Flag(name: .long, help: "Does not actually delete but just logs which tags would be deleted")
    private var dryRun: Bool = false

    @Flag(name: .long, help: "Show extra logging for debugging purposes")
    var verbose: Bool = false

    func run() throws {
        Log.isVerbose = verbose

        let tagsDeleter = try TagsDeleter(upUntilTagName: upUntilTag, limit: limit, prereleaseOnly: prereleaseOnly, dryRun: dryRun)
        let deletedTags = try tagsDeleter.run()

        guard !deletedTags.isEmpty else {
            Log.message("There were no tags found to be deleted.")
            return
        }
        Log.message("Deleted tags: \(deletedTags)")
    }
}
