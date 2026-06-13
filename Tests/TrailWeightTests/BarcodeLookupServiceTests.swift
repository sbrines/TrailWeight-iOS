import XCTest
@testable import TrailWeight

final class BarcodeLookupServiceTests: XCTestCase {

    private func data(_ string: String) -> Data { Data(string.utf8) }

    func testParsesProductWithWeightAndCategory() {
        let json = #"{"status":1,"product":{"product_name":"MSR PocketRocket Stove","quantity":"73 g"}}"#
        let product = BarcodeLookupService.parse(data(json))
        XCTAssertEqual(product?.name, "MSR PocketRocket Stove")
        XCTAssertEqual(product?.weightGrams ?? 0, 73, accuracy: 0.1)
        XCTAssertEqual(product?.category, .cooking)
    }

    func testWeightNilWhenQuantityMissing() {
        let json = #"{"status":1,"product":{"product_name":"Mystery Item"}}"#
        let product = BarcodeLookupService.parse(data(json))
        XCTAssertEqual(product?.name, "Mystery Item")
        XCTAssertNil(product?.weightGrams)
    }

    func testNilWhenNotFound() {
        XCTAssertNil(BarcodeLookupService.parse(data(#"{"status":0}"#)))
    }

    func testNilWhenNameEmpty() {
        let json = #"{"status":1,"product":{"product_name":"  "}}"#
        XCTAssertNil(BarcodeLookupService.parse(data(json)))
    }

    func testNilOnGarbage() {
        XCTAssertNil(BarcodeLookupService.parse(data("not json")))
    }
}
