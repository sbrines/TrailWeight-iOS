import XCTest
@testable import TrailWeight

final class WeightViewModelTests: XCTestCase {

    func testEmptyWhenNoTrip() {
        let vm = WeightViewModel()
        vm.recalculate()
        XCTAssertEqual(vm.summary.totalWeightGrams, 0)
    }

    // Note: recalculate()'s aggregation across a trip's pack lists traverses
    // SwiftData relationships, which requires a live ModelContext. Spinning one
    // up in the test host is unstable here (it conflicts with the app's own
    // CloudKit-backed container), so the weight math itself is covered directly
    // and deterministically by WeightCalculatorTests on explicit item arrays.
}
