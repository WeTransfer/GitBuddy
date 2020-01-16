import XCTest
import OctoKit
import Mocker
@testable import ChangelogProducerCore

final class IssueResolverTests: XCTestCase {

    private let octoKit: Octokit = Octokit()
    private var urlSession: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
        ShellInjector.shell = MockedShell.self
    }

    override func tearDown() {
        super.tearDown()
        urlSession = nil
    }

    /// It should return the issue fetched from GitHub.
    func testFetchingIssue() {
        let project = GITProject(organisation: "WeTransfer", repository: "Diagnostics")
        let input = MockChangelogInput(body: "Fixes #39")
        let resolver = IssuesResolver(octoKit: octoKit, project: project, input: input)
        Mocker.mockForIssueNumber(39)
        let issues = resolver.resolve(using: urlSession)

        XCTAssertEqual(issues?.count, 1)
        XCTAssertEqual(issues?[0].title, "Get warning for file 'style.css' after building")
    }

    /// It should return no issues if there's no issue referenced.
    func testNoReferencedIssue() {
        let project = GITProject(organisation: "WeTransfer", repository: "Diagnostics")
        let input = MockChangelogInput(body: "Pull Request description text")
        let resolver = IssuesResolver(octoKit: octoKit, project: project, input: input)
        XCTAssertNil(resolver.resolve(using: urlSession))
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
}

extension IssueResolverTests {
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
