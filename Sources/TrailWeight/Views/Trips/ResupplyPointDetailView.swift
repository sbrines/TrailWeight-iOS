import SwiftUI
import SwiftData

struct ResupplyPointDetailView: View {
    @Bindable var point: ResupplyPoint
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var appSettings
    @State private var showingAddItem = false
    @Query(sort: \GearItem.name) private var allGear: [GearItem]

    var body: some View {
        List {
            Section("Location") {
                TextField("Location name", text: $point.locationName)
                TextField("Mile Marker", value: $point.mileMarker, format: .number)
            }
            Section("Status") {
                Toggle("Sent", isOn: $point.isSent)
                Toggle("Picked Up", isOn: $point.isPickedUp)
            }
            Section("Shipping") {
                TextField("Shipping address", text: $point.shippingAddress, axis: .vertical)
                Toggle("Hold for Pickup", isOn: $point.holdForPickup)
            }
            Section("Contents (\((point.items ?? []).count) items)") {
                ForEach(point.items ?? []) { item in
                    HStack {
                        Text(item.gearItem?.name ?? "Unknown")
                        Spacer()
                        Text("×\(item.quantity)")
                            .foregroundStyle(.secondary)
                        Text(appSettings.format(item.lineWeightGrams))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            context.delete(item)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
                Button("Add Item", systemImage: "plus") {
                    showingAddItem = true
                }
            }
            Section("Notes") {
                TextEditor(text: $point.notes).frame(minHeight: 60)
            }
        }
        .navigationTitle(point.locationName)
        .trailListBackground()
        .sheet(isPresented: $showingAddItem) {
            ResupplyPointAddItemView(point: point, allGear: allGear)
        }
    }
}

struct ResupplyPointAddItemView: View {
    let point: ResupplyPoint
    let allGear: [GearItem]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    var packedGear: Set<UUID> {
        Set((point.items ?? []).compactMap { $0.gearItem?.id })
    }

    var availableGear: [GearItem] {
        allGear.filter { !packedGear.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List(availableGear) { gear in
                Button {
                    let item = ResupplyPointItem(quantity: 1)
                    item.gearItem = gear
                    context.insert(item)
                    if point.items != nil {
                        point.items?.append(item)
                    } else {
                        point.items = [item]
                    }
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(gear.name)
                            Text(appSettings.format(gear.weightGrams))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Add Item")
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
