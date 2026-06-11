import SwiftUI

struct RecommendationsView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss

    private let engine = GearRecommendationEngine()

    private var conditions: TripConditions {
        TripConditions(
            maxElevationFeet: trip.maxElevationFeet,
            minElevationFeet: trip.minElevationFeet,
            startDate: trip.startDate ?? Date(),
            durationDays: trip.durationDays,
            terrainType: trip.terrain,
            distanceMiles: trip.distanceMiles
        )
    }

    private var recommendations: [GearRecommendation] {
        engine.recommendations(for: conditions, ownedCategories: [])
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(recommendations, id: \.categoryName) { rec in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: rec.categoryIcon)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text(rec.categoryName).font(.headline)
                            Spacer()
                            Text(rec.priority.label)
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(priorityColor(rec.priority).opacity(0.15))
                                .foregroundStyle(priorityColor(rec.priority))
                                .clipShape(Capsule())
                        }
                        Text(rec.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Gear Recommendations")
            .trailListBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func priorityColor(_ p: RecommendationPriority) -> Color {
        switch p {
        case .required:  return .red
        case .strongly:  return .orange
        case .suggested: return .blue
        case .optional:  return .gray
        }
    }
}
