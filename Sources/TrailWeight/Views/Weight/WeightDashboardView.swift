import SwiftUI
import SwiftData
import Charts

struct WeightDashboardView: View {
    @Environment(WeightViewModel.self) private var viewModel
    @Environment(AppSettings.self) private var appSettings
    @Query(sort: \Trip.startDate) private var trips: [Trip]

    var body: some View {
        @Bindable var vm = viewModel
        ScrollView {
            VStack(spacing: 14) {
                tripPicker(vm: vm)

                if viewModel.selectedTrip != nil {
                    let summary = viewModel.summary
                    ClassificationHeroCard(summary: summary, settings: appSettings)
                    weightSummaryCard(summary)
                    if !summary.byCategory.isEmpty {
                        categoryCard(summary)
                    }
                }

                NavigationLink(destination: WeightHistoryView()) {
                    HStack {
                        Label("Weight History", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.body.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(Color.trailPrimary)
                    .trailCard()
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(Color.trailBackground)
        .navigationTitle("Weight")
        .onChange(of: viewModel.selectedTrip) { _, _ in viewModel.recalculate() }
    }

    @ViewBuilder
    private func tripPicker(vm: WeightViewModel) -> some View {
        @Bindable var vm = vm
        HStack {
            Image(systemName: "map.fill").foregroundStyle(Color.trailPrimary)
            Picker("Trip", selection: $vm.selectedTrip) {
                Text("Select a trip").tag(Optional<Trip>.none)
                ForEach(trips) { trip in
                    Text(trip.name).tag(Optional(trip))
                }
            }
            .tint(Color.trailPrimary)
            Spacer()
        }
        .trailCard()
        .onChange(of: viewModel.selectedTrip) { _, _ in viewModel.recalculate() }
    }

    private func weightSummaryCard(_ summary: WeightSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WEIGHT BREAKDOWN")
                .font(.caption2.weight(.bold)).tracking(0.8)
                .foregroundStyle(.secondary)
            WeightRow(label: "Base Weight",       grams: summary.baseWeightGrams,       settings: appSettings)
            WeightRow(label: "Worn Weight",       grams: summary.wornWeightGrams,       settings: appSettings)
            WeightRow(label: "Consumables",       grams: summary.consumableWeightGrams, settings: appSettings)
            Divider().background(Color.trailHairline)
            WeightRow(label: "Total Pack Weight", grams: summary.totalWeightGrams,      settings: appSettings, isBold: true)
        }
        .trailCard()
    }

    private func categoryCard(_ summary: WeightSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BY CATEGORY")
                .font(.caption2.weight(.bold)).tracking(0.8)
                .foregroundStyle(.secondary)
            Chart(summary.byCategory) { cat in
                SectorMark(angle: .value("Weight", cat.weightGrams), innerRadius: .ratio(0.58))
                    .foregroundStyle(by: .value("Category", cat.categoryName))
            }
            .frame(height: 180)

            ForEach(summary.byCategory) { cat in
                HStack(spacing: 10) {
                    Image(systemName: cat.categoryIcon)
                        .font(.footnote)
                        .foregroundStyle(Color.trailPrimary)
                        .frame(width: 22)
                    Text(cat.categoryName).font(.subheadline)
                    Spacer()
                    Text(appSettings.format(cat.weightGrams))
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    Text(String(format: "%.0f%%", cat.percentage))
                        .font(.caption2.weight(.semibold)).foregroundStyle(Color.trailPrimary)
                        .frame(width: 38, alignment: .trailing)
                }
            }
        }
        .trailCard()
    }
}

/// The hero classification card — green gradient with the headline class
/// (e.g. "ULTRALIGHT") and base weight. The visual anchor of the redesign.
private struct ClassificationHeroCard: View {
    let summary: WeightSummary
    let settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(summary.classification.uppercased())
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "scalemass.fill")
                    .font(.title3)
                    .foregroundStyle(Color.trailAmber)
            }
            Text("Base weight")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
            Text(settings.format(summary.baseWeightGrams))
                .font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient.trailHero, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.trailPine.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}

private struct WeightRow: View {
    let label: String
    let grams: Double
    let settings: AppSettings
    var isBold = false

    var body: some View {
        HStack {
            Text(label).fontWeight(isBold ? .semibold : .regular)
            Spacer()
            Text(settings.format(grams))
                .fontWeight(isBold ? .semibold : .regular)
                .monospacedDigit()
        }
    }
}
