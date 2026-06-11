import SwiftUI

struct GearItemDetailView: View {
    @Bindable var item: GearItem
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        List {
            Section("Weight") {
                LabeledContent("Weight", value: appSettings.format(item.weightGrams))
            }
            Section("Details") {
                LabeledContent("Brand", value: item.brand.isEmpty ? "—" : item.brand)
                LabeledContent("Category", value: item.category.rawValue)
                LabeledContent("Quantity owned", value: "\(item.quantityOwned)")
                LabeledContent("Consumable", value: item.isConsumable ? "Yes" : "No")
            }
            if !item.notes.isEmpty {
                Section("Notes") {
                    Text(item.notes)
                }
            }
            if !item.purchaseURL.isEmpty {
                Section("Purchase URL") {
                    if let url = URL(string: item.purchaseURL) {
                        Link(item.purchaseURL, destination: url)
                            .lineLimit(1)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(item.name)
        .trailListBackground()
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            NavigationLink("Edit", destination: AddGearItemView(existingItem: item))
        }
    }
}
