import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @Environment(AppSettings.self) private var appSettings

    @State private var page = 0

    private let infoPages: [OnboardingPage] = [
        OnboardingPage(
            icon: "backpack.fill",
            iconColor: .trailPine,
            title: "Your gear, organized",
            body: "Add everything you own to your gear inventory. Paste a product URL from REI, Zpacks, Gossamer Gear, and more — name and weight are fetched automatically."
        ),
        OnboardingPage(
            icon: "scalemass.fill",
            iconColor: .trailAmber,
            title: "Go ultralight",
            body: "Build pack lists for each trip. Track base weight, worn weight, and consumables in real time. TrailWeight tells you if you've hit ultralight or super-ultralight status."
        ),
        OnboardingPage(
            icon: "map.fill",
            iconColor: .trailPine,
            title: "Plan smarter",
            body: "Get gear recommendations based on your route elevation, season, and terrain. Plan every resupply box for long trails with mile markers and shipping details."
        ),
        OnboardingPage(
            icon: "square.and.arrow.down",
            iconColor: .trailAmber,
            title: "Import from Lighterpack",
            body: "Already on Lighterpack? Export your list as a CSV and import it here in seconds. Your data stays on your device — no account needed, no cloud required."
        ),
    ]

    private var totalPages: Int { infoPages.count + 1 } // +1 for unit picker
    private var isLastPage: Bool { page == totalPages - 1 }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(infoPages.enumerated()), id: \.offset) { index, p in
                    OnboardingPageView(page: p).tag(index)
                }

                // Unit picker page
                UnitPickerPage(selectedUnit: Binding(
                    get: { appSettings.weightUnit },
                    set: { appSettings.weightUnit = $0 }
                )).tag(infoPages.count)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            #endif
            .animation(.easeInOut, value: page)

            VStack(spacing: 12) {
                if isLastPage {
                    Button("Get Started") {
                        hasSeenOnboarding = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                } else {
                    Button("Continue") { page += 1 }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)

                    Button("Skip") { hasSeenOnboarding = true }
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .padding(.top, 16)
        }
        .background(Color.trailBackground.ignoresSafeArea())
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52))
                    .foregroundStyle(page.iconColor)
            }
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}

private struct UnitPickerPage: View {
    @Binding var selectedUnit: WeightUnit

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.trailPine.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.trailPine)
            }
            VStack(spacing: 12) {
                Text("How do you measure weight?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Choose your preferred unit. You can change this anytime in Settings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                ForEach(WeightUnit.allCases) { unit in
                    Button {
                        selectedUnit = unit
                    } label: {
                        HStack {
                            Text(unitLabel(unit))
                                .font(.body)
                            Spacer()
                            if selectedUnit == unit {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.trailPine)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedUnit == unit ? Color.trailPine.opacity(0.12) : Color.trailCard)
                                .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(selectedUnit == unit ? Color.trailPine.opacity(0.4) : Color.trailHairline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)
            Spacer()
        }
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
