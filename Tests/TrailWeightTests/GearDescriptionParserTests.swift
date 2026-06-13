import XCTest
@testable import TrailWeight

final class GearDescriptionParserTests: XCTestCase {

    func testParsesLeadingWeightAndCategory() {
        let parsed = GearDescriptionParser.parse("12 oz Patagonia Nano Puff jacket")
        XCTAssertEqual(parsed.weightGrams ?? 0, 12 * 28.3495, accuracy: 0.1)
        XCTAssertEqual(parsed.category, .clothing)
        XCTAssertTrue(parsed.name.contains("Patagonia Nano Puff"))
        XCTAssertFalse(parsed.name.lowercased().contains("oz"))
    }

    func testParsesTrailingGrams() {
        let parsed = GearDescriptionParser.parse("Nitecore NB10000 battery 150g")
        XCTAssertEqual(parsed.weightGrams ?? 0, 150, accuracy: 0.1)
        XCTAssertEqual(parsed.category, .electronics)
        XCTAssertTrue(parsed.name.contains("Nitecore"))
        XCTAssertFalse(parsed.name.contains("150"))
    }

    func testNoWeightLeavesNameIntact() {
        let parsed = GearDescriptionParser.parse("Big Agnes Copper Spur tent")
        XCTAssertNil(parsed.weightGrams)
        XCTAssertEqual(parsed.category, .shelter)
        XCTAssertEqual(parsed.name, "Big Agnes Copper Spur tent")
    }

    func testSearchURL() {
        XCTAssertNotNil(GearDescriptionParser.searchURL(for: "Zpacks Duplex"))
        XCTAssertNil(GearDescriptionParser.searchURL(for: "   "))
    }

    func testParsesKilograms() {
        let parsed = GearDescriptionParser.parse("Osprey Exos 1.1 kg backpack")
        XCTAssertEqual(parsed.weightGrams ?? 0, 1100, accuracy: 1)
        XCTAssertTrue(parsed.name.contains("Osprey Exos"))
        XCTAssertFalse(parsed.name.lowercased().contains("kg"))
    }

    func testParsesPoundsAndOunces() {
        let parsed = GearDescriptionParser.parse("Bear canister 2 lb 8 oz")
        XCTAssertEqual(parsed.weightGrams ?? 0, 2 * 453.592 + 8 * 28.3495, accuracy: 1)
        XCTAssertEqual(parsed.category, .cooking)
    }
}
