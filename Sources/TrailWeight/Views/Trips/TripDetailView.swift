import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Bindable var trip: Trip
    @Environment(TripViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var appSettings
    @State private var showingRecommendations = false
    @State private var showingAddResupply = false

    private let recommendationEngine = GearRecommendationEngine()

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Dates", value: trip.formattedDateRange)
                if trip.distanceMiles > 0 {
                    LabeledContent("Distance", value: String(format: "%.1f miles", trip.distanceMiles))
                }
                LabeledContent("Terrain", value: trip.terrain.rawValue)
                LabeledContent("Status", value: trip.status.rawValue)
            }

            if let packList = trip.packLists?.first {
                Section("Pack List (\((packList.items ?? []).count) items)") {
                    NavigationLink("View & Edit Pack List") {
                        PackListView(packList: packList)
                    }
                    LabeledContent("Base Weight",
                                   value: appSettings.format(packList.baseWeightGrams))
                    LabeledContent("Pack Weight",
                                   value: appSettings.format(packList.packWeightGrams))
                }
            }

            Section("Resupply Points") {
                ForEach((trip.resupplyPoints ?? []).sorted { $0.mileMarker < $1.mileMarker }) { point in
                    NavigationLink(destination: ResupplyPointDetailView(point: point)) {
                        VStack(alignment: .leading) {
                            Text(point.locationName)
                            Text(String(format: "Mile %.1f · %@", point.mileMarker, point.statusLabel))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            context.delete(point)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                Button("Add Resupply Point", systemImage: "plus") {
                    showingAddResupply = true
                }
            }

            Section {
                Button("Gear Recommendations") {
                    showingRecommendations = true
                }
            }
        }
        .navigationTitle(trip.name)
        .trailListBackground()
        .sheet(isPresented: $showingRecommendations) {
            RecommendationsView(trip: trip)
        }
        .sheet(isPresented: $showingAddResupply) {
            AddResupplyPointView(trip: trip, viewModel: viewModel)
        }
    }
}

struct AddResupplyPointView: View {
    let trip: Trip
    let viewModel: TripViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var locationName = ""
    @State private var mileMarker = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Location Details") {
                    TextField("Location name", text: $locationName)
                    TextField("Mile marker", text: $mileMarker)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Resupply Point")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let miles = Double(mileMarker) ?? 0
                        viewModel.addResupplyPoint(to: trip, locationName: locationName,
                                                   mileMarker: miles, context: context)
                        dismiss()
                    }
                    .disabled(locationName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
