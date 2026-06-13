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

    func testParseSearchReturnsCandidatesSkippingNameless() {
        let json = #"{"products":[{"product_name":"Stove A","quantity":"73 g"},{"product_name":"Stove B","quantity":"120 g"},{"product_name":"  "}]}"#
        let results = BarcodeLookupService.parseSearch(data(json))
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.name, "Stove A")
        XCTAssertEqual(results.first?.weightGrams ?? 0, 73, accuracy: 0.1)
    }

    func testParseSearchEmptyOnGarbage() {
        XCTAssertTrue(BarcodeLookupService.parseSearch(data("nope")).isEmpty)
    }
}
