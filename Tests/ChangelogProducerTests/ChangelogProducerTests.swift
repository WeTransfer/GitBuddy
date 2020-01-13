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
        
        let issueNumber = 4343

        issueClosingKeywords.forEach { (closingKeyword) in
            let description = examplePullRequestDescriptionUsing(closingKeyword: closingKeyword, issueNumber: issueNumber)
            XCTAssertEqual(description.resolvingIssues(), [issueNumber])
        }
    }
    
    /// It should not extract anything if no issue number is found.
    func testResolvingNoReferencedIssue() {
        let description = examplePullRequestDescriptionUsing(closingKeyword: "fixes", issueNumber: nil)
        XCTAssertTrue(description.resolvingIssues().isEmpty)
    }
    
    /// It should not extract anything if no closing keywork is found.
    func testResolvingNoClosingKeyword() {
        let issueNumber = 4343

        let description = examplePullRequestDescriptionUsing(closingKeyword: "", issueNumber: issueNumber)
        XCTAssertTrue(description.resolvingIssues().isEmpty)
    }
    
    /// It should extract mulitple issues.
    func testResolvingMultipleIssues() {
        let description = "This is a beautiful PR that close #123 for real. It also fixes #1 and fixes #2"
        let resolvedIssues = description.resolvingIssues()
        XCTAssertEqual(resolvedIssues.count, 3)
        XCTAssertEqual(Set(description.resolvingIssues()), Set([123, 1, 2]))
    }
    
    /// It should deduplicate if the same issue is closed multiple times.
    func testResolvingMultipleIssuesDedup() {
        let description = "This is a beautiful PR that close #123 for real. It also fixes #123"
        XCTAssertEqual(description.resolvingIssues(), [123])
    }
    
    /// It should not extract anything if there is no number after the #.
    func testResolvingNoNumber() {
        let description = "This is a beautiful PR that close # for real."
        XCTAssertTrue(description.resolvingIssues().isEmpty)
    }
    
    /// It should not extract anything if there is no number after the #, and it's at the end.
    func testResolvingNoNumberLast() {
        let description = "This is a beautiful PR that close #"
        XCTAssertTrue(description.resolvingIssues().isEmpty)
    }
    
    /// It should extract the issue if it's first.
    func testResolvingIssueFirst() {
        let description = "Resolves #123. Yay!"
        XCTAssertEqual(description.resolvingIssues(), [123])
    }
    
    /// It should extract the issue if it's the only thing present.
    func testResolvingIssueOnly() {
        let description = "Resolved #123"
        XCTAssertEqual(description.resolvingIssues(), [123])
    }


    static var allTests = [
        ("testPullRequestIDsFromSquashCommits", testPullRequestIDsFromSquashCommits),
        ("testPullRequestIDsFromMergeCommits", testPullRequestIDsFromMergeCommits),
        ("testResolvingReferencedIssue", testResolvingReferencedIssue)
    ]
}

extension ChangelogProducerTests {
    func examplePullRequestDescriptionUsing(closingKeyword: String, issueNumber: Int?) -> String {
        let issueNumberString = issueNumber?.description ?? ""
        
        return """
            This PR does a lot of awesome stuff.
            It even closes some issues!
            Not #3737 though. This one is too hard.

            \(closingKeyword) #\(issueNumberString)
            """

    }
}
