import XCTest
@testable import TrailWeight

final class GearFilterTests: XCTestCase {

    private func gear(_ name: String, _ category: GearCategory = .other,
                      _ grams: Double = 100, brand: String = "") -> GearItem {
        GearItem(name: name, brand: brand, category: category, weightGrams: grams)
    }

    func testSortByNameAscendingAndDescending() {
        let items = [gear("Zebra"), gear("Apple"), gear("Mango")]
        XCTAssertEqual(
            GearFilter.apply(items, searchText: "", selectedCategory: nil,
                             sortOption: .nameAscending, conceptCategory: nil).map(\.name),
            ["Apple", "Mango", "Zebra"])
        XCTAssertEqual(
            GearFilter.apply(items, searchText: "", selectedCategory: nil,
                             sortOption: .nameDescending, conceptCategory: nil).map(\.name),
            ["Zebra", "Mango", "Apple"])
    }

    func testSortByWeight() {
        let items = [gear("A", .other, 300), gear("B", .other, 100), gear("C", .other, 200)]
        XCTAssertEqual(
            GearFilter.apply(items, searchText: "", selectedCategory: nil,
                             sortOption: .weightLight, conceptCategory: nil).map(\.weightGrams),
            [100, 200, 300])
        XCTAssertEqual(
            GearFilter.apply(items, searchText: "", selectedCategory: nil,
                             sortOption: .weightHeavy, conceptCategory: nil).map(\.weightGrams),
            [300, 200, 100])
    }

    func testCategoryFilter() {
        let items = [gear("Tent", .shelter), gear("Quilt", .sleep)]
        let result = GearFilter.apply(items, searchText: "", selectedCategory: .shelter,
                                      sortOption: .nameAscending, conceptCategory: nil)
        XCTAssertEqual(result.map(\.name), ["Tent"])
    }

    func testSubstringSearchMatchesNameAndBrand() {
        let items = [gear("Tent", .shelter, brand: "Big Agnes"),
                     gear("Quilt", .sleep, brand: "EE")]
        XCTAssertEqual(
            GearFilter.apply(items, searchText: "agnes", selectedCategory: nil,
                             sortOption: .nameAscending, conceptCategory: nil).map(\.name),
            ["Tent"])
    }

    func testConceptExpansionSurfacesCategoryWithoutNameMatch() {
        let items = [gear("Nano Puff", .clothing), gear("Tent", .shelter)]
        let result = GearFilter.apply(items, searchText: "rain protection", selectedCategory: nil,
                                      sortOption: .nameAscending, conceptCategory: .clothing)
        XCTAssertEqual(result.map(\.name), ["Nano Puff"])
    }

    func testNoConceptCategoryFallsBackToSubstringOnly() {
        let items = [gear("Nano Puff", .clothing), gear("Tent", .shelter)]
        let result = GearFilter.apply(items, searchText: "rain protection", selectedCategory: nil,
                                      sortOption: .nameAscending, conceptCategory: nil)
        XCTAssertTrue(result.isEmpty)
    }
}
