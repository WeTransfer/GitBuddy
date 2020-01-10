import XCTest
@testable import ChangelogProducerCore

final class ChangelogProducerTests: XCTestCase {

    /// It should extract pull request IDs from squash merges.
    func testPullRequestIDsFromSquashCommits() throws {
        let gitLogOutput = """
            * Fix bucket deeplinking after adding content (#5130) via Antoine van der Lee
            * Fix CI for Coyote #trivial (#5114) via Antoine van der Lee
            * Update to 4.3.1 via Antoine van der Lee
            """
        XCTAssertEqual(gitLogOutput.pullRequestIDs(), [5114, 5130])
    }

    /// It should extract pull request from merge commits.
    func testPullRequestIDsFromMergeCommits() throws {
            let gitLogOutput = """
                * Merge pull request #65 from BalestraPatrick/profiles-devices-endpoints via Antoine van der Lee
                * Merge pull request #62 from hexagons/issue/42 via Antoine van der Lee
                """
            XCTAssertEqual(gitLogOutput.pullRequestIDs(), [62, 65])
        }

    static var allTests = [
        ("testPullRequestIDsFromSquashCommits", testPullRequestIDsFromSquashCommits),
        ("testPullRequestIDsFromMergeCommits", testPullRequestIDsFromMergeCommits)
    ]
}
