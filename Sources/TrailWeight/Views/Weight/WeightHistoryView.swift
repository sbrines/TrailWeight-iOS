import SwiftUI
import SwiftData
import Charts

struct WeightHistoryView: View {
    @Query(sort: \WeightSnapshot.recordedAt, order: .forward) private var snapshots: [WeightSnapshot]
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        Group {
            if snapshots.isEmpty {
                ContentUnavailableView(
                    "No weight history yet",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Save a pack list's weight to start tracking your progress toward ultralight.")
                )
            } else {
                List {
                    Section("Base Weight Trend") {
                        Chart(snapshots) { snap in
                            LineMark(
                                x: .value("Date", snap.recordedAt),
                                y: .value("Base", appSettings.convert(snap.baseWeightGrams))
                            )
                            .foregroundStyle(Color.trailPine)
                            PointMark(
                                x: .value("Date", snap.recordedAt),
                                y: .value("Base", appSettings.convert(snap.baseWeightGrams))
                            )
                            .foregroundStyle(Color.trailPine)
                            .annotation(position: .top) {
                                Text(snap.classification)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }

                            // SUL threshold line
                            RuleMark(y: .value("SUL", appSettings.convert(2_270)))
                                .foregroundStyle(.green.opacity(0.4))
                                .lineStyle(StrokeStyle(dash: [4]))
                                .annotation(position: .trailing) {
                                    Text("SUL").font(.system(size: 9)).foregroundStyle(.green)
                                }

                            // UL threshold line
                            RuleMark(y: .value("UL", appSettings.convert(4_540)))
                                .foregroundStyle(.orange.opacity(0.4))
                                .lineStyle(StrokeStyle(dash: [4]))
                                .annotation(position: .trailing) {
                                    Text("UL").font(.system(size: 9)).foregroundStyle(.orange)
                                }
                        }
                        .frame(height: 200)
                        .chartYAxisLabel(appSettings.unitLabel)
                    }

                    Section("History") {
                        ForEach(snapshots.reversed()) { snap in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snap.tripName).font(.body)
                                    Text(snap.recordedAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(appSettings.format(snap.baseWeightGrams))
                                        .font(.body.monospacedDigit())
                                    Text(snap.classification)
                                        .font(.caption)
                                        .foregroundStyle(classificationColor(snap.classification))
                                }
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { snapshots.reversed()[$0] }.forEach { context.delete($0) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Weight History")
        .trailListBackground()
    }

    private func classificationColor(_ c: String) -> Color {
        switch c {
        case "SUL": return .green
        case "UL":  return .blue
        case "Lightweight": return .orange
        default:    return .secondary
        }
    }
}
