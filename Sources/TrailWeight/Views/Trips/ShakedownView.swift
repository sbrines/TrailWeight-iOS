import SwiftUI

/// Presents a pack-list "shakedown": rule-based findings plus, when system AI
/// is available, a friendly narrative summary on top.
struct ShakedownView: View {
    let items: [PackListItem]
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss

    @State private var narrative: String?
    @State private var loadingNarrative = false

    private var findings: [ShakedownFinding] {
        ShakedownAdvisor.analyze(items: items, settings: appSettings)
    }

    var body: some View {
        NavigationStack {
            List {
                if loadingNarrative {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Reviewing your kit…").foregroundStyle(.secondary)
                    }
                } else if let narrative {
                    Section("Advisor") {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkles").foregroundStyle(Color.trailPine)
                            Text(narrative).font(.callout)
                        }
                    }
                }

                Section(narrative == nil ? "Findings" : "Details") {
                    ForEach(findings) { finding in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: finding.symbol)
                                .foregroundStyle(color(for: finding.kind))
                                .frame(width: 22)
                            Text(finding.text).font(.subheadline)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Shakedown")
            .trailListBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await loadNarrative() }
        }
    }

    private func loadNarrative() async {
        guard GearCategoryClassifier.isSystemAIAvailable else { return }
        loadingNarrative = true
        narrative = await ShakedownAdvisor.narrative(for: findings)
        loadingNarrative = false
    }

    private func color(for kind: ShakedownFinding.Kind) -> Color {
        switch kind {
        case .info:       return .trailPine
        case .suggestion: return .trailAmber
        case .warning:    return .red
        }
    }
}
