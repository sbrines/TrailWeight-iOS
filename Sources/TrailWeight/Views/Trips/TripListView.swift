import SwiftUI
import SwiftData

struct TripListView: View {
    @Environment(TripViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.startDate) private var allTrips: [Trip]

    var body: some View {
        @Bindable var vm = viewModel
        List {
            ForEach(viewModel.filtered(allTrips)) { trip in
                ZStack {
                    NavigationLink(destination: TripDetailView(trip: trip)) { EmptyView() }
                        .opacity(0)
                    TripRow(trip: trip)
                }
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete { offsets in
                offsets.map { viewModel.filtered(allTrips)[$0] }.forEach {
                    viewModel.deleteTrip($0, from: context)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.trailBackground)
        .searchable(text: $vm.searchText, prompt: "Search trips")
        .navigationTitle("Trips")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    viewModel.showingAddTripSheet = true
                }
            }
        }
        .sheet(isPresented: $vm.showingAddTripSheet) {
            AddTripView()
        }
    }
}

private struct TripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "map.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.trailPrimary)
                Text(trip.name).font(.headline)
                Spacer(minLength: 8)
                Text(trip.status.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.trailPineDeep)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Color.trailAmber.opacity(0.22))
                    .clipShape(Capsule())
            }
            Text(trip.formattedDateRange)
                .font(.caption)
                .foregroundStyle(.secondary)
            if trip.distanceMiles > 0 {
                Label(String(format: "%.1f miles · %@", trip.distanceMiles, trip.terrain.rawValue),
                      systemImage: "figure.hiking")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.trailCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.trailHairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
