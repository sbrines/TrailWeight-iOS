import XCTest
@testable import TrailWeight

final class ShakedownAdvisorTests: XCTestCase {

    private func gear(_ name: String, _ category: GearCategory, _ grams: Double) -> GearItem {
        GearItem(name: name, category: category, weightGrams: grams)
    }

    private func pack(_ gear: GearItem, worn: Bool = false, qty: Int = 1) -> PackListItem {
        PackListItem(gearItem: gear, packedQuantity: qty, isWorn: worn)
    }

    func testEmptyListReturnsSingleInfoFinding() {
        let findings = ShakedownAdvisor.analyze(items: [], settings: AppSettings())
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.kind, .info)
    }

    func testClassificationFindingFirst() {
        let items = [pack(gear("Quilt", .sleep, 600))]
        let findings = ShakedownAdvisor.analyze(items: items, settings: AppSettings())
        XCTAssertEqual(findings.first?.kind, .info)
        XCTAssertTrue(findings.first?.text.contains("Base weight") == true)
    }

    func testHeaviestItemIsCalledOut() {
        let items = [
            pack(gear("Heavy Tent", .shelter, 2000)),
            pack(gear("Light Quilt", .sleep, 500)),
        ]
        let findings = ShakedownAdvisor.analyze(items: items, settings: AppSettings())
        XCTAssertTrue(findings.contains { $0.text.contains("Heavy Tent") })
    }

    func testRedundantShelterWarning() {
        let items = [
            pack(gear("Tent A", .shelter, 800)),
            pack(gear("Tent B", .shelter, 700)),
        ]
        let findings = ShakedownAdvisor.analyze(items: items, settings: AppSettings())
        XCTAssertTrue(findings.contains { $0.kind == .warning && $0.text.lowercased().contains("shelter") })
    }

    func testWornAndConsumableExcludedFromHeaviestBase() {
        // The food item is heaviest overall but is a consumable, so the heaviest
        // *base* call-out should be the tent, not the food.
        let items = [
            pack(gear("Tent", .shelter, 900)),
            pack(gear("Food Bag", .food, 3000)),
        ]
        let findings = ShakedownAdvisor.analyze(items: items, settings: AppSettings())
        XCTAssertTrue(findings.contains { $0.text.contains("Tent") })
        XCTAssertFalse(findings.contains { $0.text.contains("Food Bag") })
    }
}
