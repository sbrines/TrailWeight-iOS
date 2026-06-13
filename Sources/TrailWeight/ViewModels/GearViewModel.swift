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
        // Semantic assist (system-AI gated): map the query to a concept category
        // so "rain protection" surfaces a jacket even with no name match. Falls
        // back to plain substring search when AI is unavailable.
        let conceptCategory = (!searchText.isEmpty && GearCategoryClassifier.isSystemAIAvailable)
            ? GearCategoryClassifier.shared.classify(name: searchText)
            : nil
        return GearFilter.apply(items, searchText: searchText, selectedCategory: selectedCategory,
                                sortOption: sortOption, conceptCategory: conceptCategory)
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
