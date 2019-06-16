import XCTest
@testable import SwiftFS

final class SwiftFSTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftFS().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
