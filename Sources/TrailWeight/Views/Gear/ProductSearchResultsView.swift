import SwiftUI

/// A tappable list of Open Products Facts search candidates. Selecting one
/// fills the Add Gear form from that product.
struct ProductSearchResultsView: View {
    let results: [BarcodeProduct]
    let onSelect: (BarcodeProduct) -> Void

    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(results) { product in
                Button {
                    onSelect(product)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            if let category = product.category {
                                Text(category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer(minLength: 8)
                        if let grams = product.weightGrams {
                            Text(appSettings.format(grams))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(Color.trailPrimary)
                        } else {
                            Text("no weight")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("Search Results")
            .trailListBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
