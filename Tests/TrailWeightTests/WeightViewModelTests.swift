import XCTest
@testable import TrailWeight

final class WeightViewModelTests: XCTestCase {

    private func packList(_ name: String, _ items: [PackListItem]) -> PackList {
        let list = PackList(name: name)
        list.items = items
        return list
    }

    private func item(_ grams: Double, worn: Bool = false, consumable: Bool = false) -> PackListItem {
        let gear = GearItem(name: "Item", category: .other, weightGrams: grams, isConsumable: consumable)
        return PackListItem(gearItem: gear, isWorn: worn)
    }

    func testEmptyWhenNoTrip() {
        let vm = WeightViewModel()
        vm.recalculate()
        XCTAssertEqual(vm.summary.totalWeightGrams, 0)
    }

    func testEmptyWhenTripHasNoPackLists() {
        let vm = WeightViewModel()
        let trip = Trip(name: "JMT")
        trip.packLists = []
        vm.selectedTrip = trip
        vm.recalculate()
        XCTAssertEqual(vm.summary.totalWeightGrams, 0)
    }

    func testAggregatesAcrossEveryPackList() {
        let trip = Trip(name: "JMT")
        trip.packLists = [
            packList("Section A", [item(1000), item(500, worn: true)]),
            packList("Section B", [item(300), item(200, consumable: true)]),
        ]
        let vm = WeightViewModel()
        vm.selectedTrip = trip
        vm.recalculate()

        // Total spans both pack lists: 1000 + 500 + 300 + 200.
        XCTAssertEqual(vm.summary.totalWeightGrams, 2000)
        // Base excludes worn (500) and consumable (200): 1000 + 300.
        XCTAssertEqual(vm.summary.baseWeightGrams, 1300)
        XCTAssertEqual(vm.summary.wornWeightGrams, 500)
        XCTAssertEqual(vm.summary.consumableWeightGrams, 200)
    }
}
