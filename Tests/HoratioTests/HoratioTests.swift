import XCTest
@testable import Horatio

final class HoratioTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Horatio().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
