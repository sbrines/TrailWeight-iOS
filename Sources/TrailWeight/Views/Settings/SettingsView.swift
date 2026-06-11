import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        List {
            Section {
                Picker("Weight unit", selection: Binding(
                    get: { appSettings.weightUnit },
                    set: { appSettings.weightUnit = $0 }
                )) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unitLabel(unit)).tag(unit)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Display Units")
            } footer: {
                Text("Applies everywhere weight is shown in the app.")
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                if let privacyURL = URL(string: "https://sbrines.github.io/TrailWeight-Web/privacy.html") {
                    Link("Privacy Policy", destination: privacyURL)
                }
            }
        }
        .navigationTitle("Settings")
        .trailListBackground()
        .navigationBarTitleDisplayMode(.large)
    }

    private func unitLabel(_ unit: WeightUnit) -> String {
        switch unit {
        case .grams:     return "Grams (g)"
        case .ounces:    return "Ounces (oz)"
        case .kilograms: return "Kilograms (kg)"
        case .pounds:    return "Pounds (lb)"
        }
    }
}
