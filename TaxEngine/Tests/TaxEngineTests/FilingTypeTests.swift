import XCTest
@testable import TaxEngine

final class FilingTypeTests: XCTestCase {
    func testDisplayNames() {
        XCTAssertEqual(FilingType.blue.displayName, "青色申告")
        XCTAssertEqual(FilingType.white.displayName, "白色申告")
    }
}
