import XCTest
@testable import TrailWeight

final class WeightParserTests: XCTestCase {

    func testGramsOnly() {
        XCTAssertEqual(WeightParser.parseToGrams("119g"), 119)
        XCTAssertEqual(WeightParser.parseToGrams("119 g"), 119)
        XCTAssertEqual(WeightParser.parseToGrams("539 grams"), 539)
    }

    func testOuncesOnly() {
        XCTAssertEqual(WeightParser.parseToGrams("4 oz")!, 4 * 28.3495, accuracy: 0.01)
        XCTAssertEqual(WeightParser.parseToGrams("4.2 oz")!, 4.2 * 28.3495, accuracy: 0.01)
        XCTAssertEqual(WeightParser.parseToGrams("4 ounces")!, 4 * 28.3495, accuracy: 0.01)
    }

    func testPoundsOnly() {
        XCTAssertEqual(WeightParser.parseToGrams("0.26 lbs")!, 0.26 * 453.592, accuracy: 0.01)
        XCTAssertEqual(WeightParser.parseToGrams("1 lb")!, 453.592, accuracy: 0.01)
    }

    func testPoundsAndOunces() {
        XCTAssertEqual(WeightParser.parseToGrams("1 lb 4 oz")!, 453.592 + 4 * 28.3495, accuracy: 0.1)
        XCTAssertEqual(WeightParser.parseToGrams("3 lbs. 14 oz.")!, 3 * 453.592 + 14 * 28.3495, accuracy: 0.1)
    }

    func testDualFormat() {
        XCTAssertEqual(WeightParser.parseToGrams("4 oz / 113g")!, 113, accuracy: 0.01)
        XCTAssertEqual(WeightParser.parseToGrams("19.0 oz (539 g)")!, 539, accuracy: 0.01)
        XCTAssertEqual(WeightParser.parseToGrams("4 oz (113 g)")!, 113, accuracy: 0.01)
        // Spelled-out "ounces" should still prefer the grams component
        XCTAssertEqual(WeightParser.parseToGrams("5 ounces (140 g)")!, 140, accuracy: 0.01)
    }

    func testKilograms() {
        XCTAssertEqual(WeightParser.parseToGrams("1.31 kg")!, 1310, accuracy: 0.01)
        XCTAssertEqual(WeightParser.parseToGrams("0.85 kg")!, 850, accuracy: 0.01)
    }

    func testNilForUnparseable() {
        XCTAssertNil(WeightParser.parseToGrams("not a weight"))
        XCTAssertNil(WeightParser.parseToGrams(""))
    }
}
