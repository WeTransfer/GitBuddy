# ChangelogProducer
A changelog generator written in Swift for GitHub repositories.

### Installation using [Mint](https://github.com/yonaskolb/mint)
You can install the Changelog Producer using Mint as follows:

```
$ mint install WeTransfer/ChangelogProducer
```

After that you can directly use it:

```
$ changelogproducer --help
OVERVIEW: Create a changelog for GitHub repositories

USAGE: ChangelogProducer <options>

OPTIONS:
  --baseBranch, -b   The base branch to compare with
  --sinceTag, -s     The tag to use as a base
  --verbose          Show extra logging for debugging purposes
  --help             Display available options
```

### Development
- `cd` into the repository
- run `swift package generate-xcodeproj` (Generates an Xcode project for development)
- Run the following command from the project you're using it for:

```bash
swift run --package-path ../ChangelogProducer/ ChangelogProducer -s 4.3.0b13951 -b develop --verbose
```

### Useful resources
- [Building a command line tool using the Swift Package Manager](https://www.swiftbysundell.com/articles/building-a-command-line-tool-using-the-swift-package-manager/)
