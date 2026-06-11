import SwiftUI

struct AddTripView: View {
    @Environment(TripViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var trailName = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3)
    @State private var distanceMiles = ""
    @State private var terrain: TerrainType = .mixed
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Trip name", text: $name)
                    TextField("Trail name", text: $trailName)
                }
                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                Section("Details") {
                    HStack {
                        TextField("Distance", text: $distanceMiles)
                            .keyboardType(.decimalPad)
                        Text("miles").foregroundStyle(.secondary)
                    }
                    Picker("Terrain", selection: $terrain) {
                        ForEach(TerrainType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
            }
            .navigationTitle("New Trip")
            .trailListBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }.disabled(name.isEmpty)
                }
            }
        }
    }

    private func create() {
        let trip = viewModel.createTrip(name: name, in: context)
        trip.trailName = trailName
        trip.startDate = startDate
        trip.endDate = endDate
        trip.distanceMiles = Double(distanceMiles) ?? 0
        trip.terrain = terrain
        trip.notes = notes
        try? context.save()
        dismiss()
    }
}
