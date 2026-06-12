import Foundation
import SwiftData
import Observation

enum GearSortOption: String, CaseIterable, Identifiable {
    case nameAscending  = "Name (A–Z)"
    case nameDescending = "Name (Z–A)"
    case weightLight    = "Lightest First"
    case weightHeavy    = "Heaviest First"
    case category       = "Category"
    case recentlyAdded  = "Recently Added"

    var id: String { rawValue }
}

@Observable
final class GearViewModel {
    var searchText = ""
    var selectedCategory: GearCategory? = nil
    var sortOption: GearSortOption = .nameAscending
    var showingAddSheet = false
    var showingImportSheet = false
    var isFetchingURL = false
    var urlFetchError: String? = nil

    private let fetcher = URLMetadataFetcher()

    func filtered(_ items: [GearItem]) -> [GearItem] {
        var result = items
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            // Semantic assist (system-AI gated): map the query to a concept
            // category so "rain protection" surfaces a jacket even with no name
            // match. Falls back to plain substring search when AI is unavailable.
            let conceptCategory = GearCategoryClassifier.isSystemAIAvailable
                ? GearCategoryClassifier.shared.classify(name: searchText)
                : nil
            result = result.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.brand.localizedCaseInsensitiveContains(searchText) ||
                (conceptCategory != nil && item.category == conceptCategory)
            }
        }
        return sorted(result)
    }

    private func sorted(_ items: [GearItem]) -> [GearItem] {
        switch sortOption {
        case .nameAscending:  return items.sorted { $0.name < $1.name }
        case .nameDescending: return items.sorted { $0.name > $1.name }
        case .weightLight:    return items.sorted { $0.weightGrams < $1.weightGrams }
        case .weightHeavy:    return items.sorted { $0.weightGrams > $1.weightGrams }
        case .category:       return items.sorted { $0.categoryRawValue < $1.categoryRawValue }
        case .recentlyAdded:  return items.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func delete(_ items: [GearItem], from context: ModelContext) {
        items.forEach { context.delete($0) }
        try? context.save()
    }

    @MainActor
    func fetchMetadata(from urlString: String) async -> GearItemMetadata? {
        guard let url = URL(string: urlString) else {
            urlFetchError = "Invalid URL"
            return nil
        }
        isFetchingURL = true
        urlFetchError = nil
        defer { isFetchingURL = false }
        do {
            return try await fetcher.fetch(url: url)
        } catch {
            urlFetchError = error.localizedDescription
            return nil
        }
    }
}
