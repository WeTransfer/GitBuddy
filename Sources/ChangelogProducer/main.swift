import ChangelogProducerCore

let changelogProducer = ChangelogProducer()

do {
    try changelogProducer.run()
} catch {
    print("Whoops! An error occurred: \(error)")
}
