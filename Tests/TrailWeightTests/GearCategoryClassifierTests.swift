import XCTest
@testable import TrailWeight

final class GearCategoryClassifierTests: XCTestCase {

    private let classifier = GearCategoryClassifier.shared

    func testLexiconHits() {
        XCTAssertEqual(classifier.classify(name: "Zpacks Duplex Tent"), .shelter)
        XCTAssertEqual(classifier.classify(name: "Enlightened Equipment Revelation Quilt"), .sleep)
        XCTAssertEqual(classifier.classify(name: "Sawyer Squeeze Water Filter"), .water)
        XCTAssertEqual(classifier.classify(name: "Nitecore NB10000 Battery"), .electronics)
        XCTAssertEqual(classifier.classify(name: "BRS-3000T Stove"), .cooking)
        XCTAssertEqual(classifier.classify(name: "Altra Lone Peak Shoes"), .footwear)
        XCTAssertEqual(classifier.classify(name: "Patagonia Nano Puff Jacket"), .clothing)
    }

    func testCaseAndPunctuationInsensitive() {
        XCTAssertEqual(classifier.classify(name: "HEADLAMP, rechargeable"), .electronics)
        XCTAssertEqual(classifier.classify(name: "first-aid kit"), .firstAid)
    }

    func testNoConfidentMatchReturnsNil() {
        XCTAssertNil(classifier.classify(name: "xyzzy qwerty"))
        XCTAssertNil(classifier.classify(name: ""))
    }

    func testImportInfersCategoryWhenLabelMissing() throws {
        // Category column blank — with the assist on, the classifier fills it in.
        let csv = """
        Item Name,Category,desc,qty,weight,unit,url,price,worn,consumable
        Big Agnes Tiger Wall Tent,,,1,1100,g,,,0,0
        """
        let rows = try LighterpackService.import(csv: csv)
        let items = LighterpackService.rowsToGearItems(rows, smartCategorization: true)
        XCTAssertEqual(items.first?.category, .shelter)
    }

    func testImportFallsBackWhenSystemAIUnavailable() throws {
        // Assist off (system AI unavailable) — original behavior: stays Other.
        let csv = """
        Item Name,Category,desc,qty,weight,unit,url,price,worn,consumable
        Big Agnes Tiger Wall Tent,,,1,1100,g,,,0,0
        """
        let rows = try LighterpackService.import(csv: csv)
        let items = LighterpackService.rowsToGearItems(rows, smartCategorization: false)
        XCTAssertEqual(items.first?.category, .other)
    }

    func testImportRespectsExplicitCategory() throws {
        // A valid label is trusted verbatim regardless of the assist.
        let csv = """
        Item Name,Category,desc,qty,weight,unit,url,price,worn,consumable
        Random Tent Thing,Electronics,,1,100,g,,,0,0
        """
        let rows = try LighterpackService.import(csv: csv)
        let items = LighterpackService.rowsToGearItems(rows, smartCategorization: true)
        XCTAssertEqual(items.first?.category, .electronics)
    }
}
