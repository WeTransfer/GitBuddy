# GitBuddy
Your buddy in managing and maintaining GitHub repositories.

<p align="center">
<img src="https://app.bitrise.io/app/257a09239a13f301.svg?token=1iMSavdhOwGWKuYtK9fgoQ"/>
<img src="https://img.shields.io/badge/language-swift5.1-f48041.svg?style=flat"/>
<img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat"/>
</p>

GitBuddy helps you with:

- [x] Generating a changelog
- [ ] Creating GitHub releases
- [ ] Commenting on issues and PRs when a releases contained the related code changes
- [ ] Managing stale issues

### Example changelog
This is an example taken from [Mocker](https://github.com/WeTransfer/Mocker/releases/tag/2.0.1)

----

- Switch over to Danger-Swift & Bitrise ([#34](https://github.com/WeTransfer/Mocker/pull/34)) via @AvdLee
- Fix important mismatch for getting the right mock ([#31](https://github.com/WeTransfer/Mocker/pull/31)) via @AvdLee

----

### Installation using [Mint](https://github.com/yonaskolb/mint)
You can install GitBuddy using Mint as follows:

```
$ mint install WeTransfer/GitBuddy
```

After that you can directly use it:

```
$ gitbuddy --help
OVERVIEW: Your buddy in managing and maintaining GitHub repositories.

USAGE: GitBuddy <options>

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
swift run --package-path ../GitBuddy/ GitBuddy -s 4.3.0b13951 -b develop --verbose
```
