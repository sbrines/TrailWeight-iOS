import Foundation

/// Pure gear-list filtering and sorting, extracted from `GearViewModel` so the
/// decision logic — including the semantic concept-expansion — is unit-testable
/// without standing up the view model and its dependencies.
enum GearFilter {

    /// - Parameter conceptCategory: a category the search query maps to (via the
    ///   on-device classifier) when system AI is on; `nil` disables the semantic
    ///   expansion, leaving plain substring matching.
    static func apply(
        _ items: [GearItem],
        searchText: String,
        selectedCategory: GearCategory?,
        sortOption: GearSortOption,
        conceptCategory: GearCategory?
    ) -> [GearItem] {
        var result = items
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            result = result.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.brand.localizedCaseInsensitiveContains(searchText) ||
                (conceptCategory != nil && item.category == conceptCategory)
            }
        }
        return sorted(result, by: sortOption)
    }

    static func sorted(_ items: [GearItem], by option: GearSortOption) -> [GearItem] {
        switch option {
        case .nameAscending:  return items.sorted { $0.name < $1.name }
        case .nameDescending: return items.sorted { $0.name > $1.name }
        case .weightLight:    return items.sorted { $0.weightGrams < $1.weightGrams }
        case .weightHeavy:    return items.sorted { $0.weightGrams > $1.weightGrams }
        case .category:       return items.sorted { $0.categoryRawValue < $1.categoryRawValue }
        case .recentlyAdded:  return items.sorted { $0.createdAt > $1.createdAt }
        }
    }
}
