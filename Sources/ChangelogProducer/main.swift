import ChangelogProducerCore

do {
    let changelogProducer = try ChangelogProducer()
    try changelogProducer.run()
} catch {
    print("Whoops! An error occurred: \(error)")
}
