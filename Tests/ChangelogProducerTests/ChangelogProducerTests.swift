import XCTest
@testable import ChangelogProducerCore

final class ChangelogProducerTests: XCTestCase {

    /// It should extract pull request IDs from squash merges.
    func testPullRequestIDsFromSquashCommits() {
        let gitLogOutput = """
            * Fix bucket deeplinking after adding content (#5130) via Antoine van der Lee
            * Fix CI for Coyote #trivial (#5114) via Antoine van der Lee
            * Update to 4.3.1 via Antoine van der Lee
            """
        XCTAssertEqual(gitLogOutput.pullRequestIDs(), [5114, 5130])
    }

    /// It should extract pull request from merge commits.
    func testPullRequestIDsFromMergeCommits() {
        let gitLogOutput = """
            * Merge pull request #65 from BalestraPatrick/profiles-devices-endpoints via Antoine van der Lee
            * Merge pull request #62 from hexagons/issue/42 via Antoine van der Lee
            """
        XCTAssertEqual(gitLogOutput.pullRequestIDs(), [62, 65])
    }

    /// It should extract the fixed issue from the Pull Request body.
    func testResolvingReferencedIssue() {
        // See this code as an example: https://github.com/fastlane/issue-bot/blob/457348717d99e5ffde34ca1619e7253ed51ec172/bot.rb#L456

        let issueClosingKeywords = [
            "close",
            "Closes",
            "closed",
            "fix",
            "fixes",
            "Fixed",
            "resolve",
            "Resolves",
            "resolved"
        ]

        issueClosingKeywords.forEach { (closingKeyword) in
            let description = examplePullRequestDescriptionUsing(closingKeyword: closingKeyword)
            XCTAssertEqual(description.resolvingIssue(), 4343)
        }
    }

    static var allTests = [
        ("testPullRequestIDsFromSquashCommits", testPullRequestIDsFromSquashCommits),
        ("testPullRequestIDsFromMergeCommits", testPullRequestIDsFromMergeCommits)
    ]
}

extension ChangelogProducerTests {
    func examplePullRequestDescriptionUsing(closingKeyword: String) -> String {
        return """
            This PR does a lot of awesome stuff.

            \(closingKeyword) #4343
            """

    }
}
