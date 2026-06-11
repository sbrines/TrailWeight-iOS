import SwiftUI
import SwiftData

struct PackListView: View {
    @Bindable var packList: PackList
    @Environment(TripViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @Query(sort: \GearItem.name) private var allGear: [GearItem]
    @State private var showingAddGear = false

    private var grouped: [(category: GearCategory, items: [PackListItem])] {
        let dict = Dictionary(grouping: packList.items ?? []) { item in
            item.gearItem?.category ?? .other
        }
        return dict.map { (category: $0.key, items: $0.value) }
            .sorted { $0.category.rawValue < $1.category.rawValue }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    WeightPill(label: "Base", grams: packList.baseWeightGrams)
                    Spacer()
                    WeightPill(label: "Pack", grams: packList.packWeightGrams)
                    Spacer()
                    WeightPill(label: "Worn", grams: packList.wornWeightGrams)
                }
            }

            ForEach(grouped, id: \.category) { group in
                Section(group.category.rawValue) {
                    ForEach(group.items) { item in
                        PackListItemRow(item: item, viewModel: viewModel,
                                       packList: packList, context: context)
                    }
                }
            }
        }
        .navigationTitle(packList.name)
        .trailListBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Item", systemImage: "plus") { showingAddGear = true }
            }
        }
        .sheet(isPresented: $showingAddGear) {
            GearPickerView(packList: packList, allGear: allGear)
        }
    }
}

private struct WeightPill: View {
    let label: String
    let grams: Double
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(appSettings.format(grams)).font(.caption.monospacedDigit())
        }
    }
}

private struct PackListItemRow: View {
    @Bindable var item: PackListItem
    let viewModel: TripViewModel
    let packList: PackList
    let context: ModelContext
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.gearItem?.name ?? "Unknown")
                HStack {
                    if item.isWorn { Label("Worn", systemImage: "figure.walk").font(.caption2) }
                    Text(appSettings.format(item.totalWeightGrams))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Stepper("\(item.packedQuantity)", value: $item.packedQuantity,
                    in: 0...(item.gearItem?.quantityOwned ?? 1))
                .labelsHidden()
                .fixedSize()
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.removeItem(item, from: packList, context: context)
            } label: {
                Label("Remove", systemImage: "trash")
            }
            Button {
                item.isWorn.toggle()
            } label: {
                Label(item.isWorn ? "Un-wear" : "Wear", systemImage: "figure.walk")
            }
            .tint(.blue)
        }
    }
}

struct GearPickerView: View {
    let packList: PackList
    let allGear: [GearItem]
    @Environment(TripViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    private var unpacked: [GearItem] {
        let packedIDs = Set((packList.items ?? []).compactMap { $0.gearItem?.id })
        return allGear.filter { !packedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List(unpacked) { gear in
                Button {
                    viewModel.addGearItem(gear, to: packList, context: context)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: gear.category.symbolName).foregroundStyle(gear.category.color)
                        VStack(alignment: .leading) {
                            Text(gear.name)
                            Text(appSettings.format(gear.weightGrams)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Add Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
