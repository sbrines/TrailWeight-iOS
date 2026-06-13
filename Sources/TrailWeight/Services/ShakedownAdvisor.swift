import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// A single piece of pack-list feedback.
struct ShakedownFinding: Identifiable {
    enum Kind { case info, suggestion, warning }
    let id = UUID()
    let kind: Kind
    let symbol: String
    let text: String
}

/// Produces a "shakedown" of a pack list — the ultralight ritual of reviewing a
/// kit for weight to cut. The rule-based analysis is deterministic and always
/// available; when the device's system AI (Apple Intelligence) is on, it can
/// additionally phrase the findings as a friendly narrative.
enum ShakedownAdvisor {

    // MARK: Rule-based analysis (always available)

    static func analyze(items: [PackListItem], settings: AppSettings) -> [ShakedownFinding] {
        let summary = WeightCalculator.calculate(from: items)
        let fmt = settings.format
        var findings: [ShakedownFinding] = []

        guard summary.totalWeightGrams > 0 else {
            findings.append(ShakedownFinding(kind: .info, symbol: "tray",
                text: "This pack list is empty — add gear to get a shakedown."))
            return findings
        }

        findings.append(ShakedownFinding(kind: .info, symbol: "scalemass",
            text: "Base weight \(fmt(summary.baseWeightGrams)) — \(summary.classification). "
                + "Total \(fmt(summary.totalWeightGrams)) with food and water."))

        // Base items only (count toward base weight, not worn, not consumable).
        let baseItems: [(name: String, grams: Double, category: GearCategory)] = items.compactMap { item in
            guard let gear = item.gearItem, !item.isWorn, !gear.isConsumable,
                  gear.category.countsTowardBaseWeight else { return nil }
            return (gear.name, gear.weightGrams * Double(item.packedQuantity), gear.category)
        }

        // Heaviest single item — the biggest single payoff.
        if let heaviest = baseItems.max(by: { $0.grams < $1.grams }), summary.baseWeightGrams > 0 {
            let pct = Int((heaviest.grams / summary.baseWeightGrams * 100).rounded())
            findings.append(ShakedownFinding(kind: .suggestion, symbol: "arrow.down.circle",
                text: "Heaviest item: \(heaviest.name) at \(fmt(heaviest.grams)) (\(pct)% of base weight). "
                    + "Lightening this gives the biggest single payoff."))
        }

        // Whether any real red flag (not just the informational heaviest item)
        // was raised, so we can reassure the user when the kit is clean.
        var flagged = false

        // Category concentration — flag a non-Big-3 category eating into base.
        let byCategory = Dictionary(grouping: baseItems, by: { $0.category })
            .map { (category: $0.key, grams: $0.value.reduce(0) { $0 + $1.grams }) }
            .sorted { $0.grams > $1.grams }
        if let top = byCategory.first, summary.baseWeightGrams > 0 {
            let pct = Int((top.grams / summary.baseWeightGrams * 100).rounded())
            if pct >= 25 {
                flagged = true
                findings.append(ShakedownFinding(kind: .suggestion, symbol: "chart.pie",
                    text: "\(top.category.rawValue) is \(pct)% of your base weight (\(fmt(top.grams))). "
                        + "That's a lot in one category — worth a closer look."))
            }
        }

        // Redundancy — more than one item in a "you usually need one" category.
        let singleItemCategories: [GearCategory] = [.shelter, .sleep, .cooking, .navigation]
        for category in singleItemCategories {
            let inCategory = baseItems.filter { $0.category == category }
            if inCategory.count > 1 {
                flagged = true
                findings.append(ShakedownFinding(kind: .warning, symbol: "doc.on.doc",
                    text: "You're carrying \(inCategory.count) \(category.rawValue.lowercased()) items. "
                        + "Most trips only need one — consider dropping a backup."))
            }
        }

        if !flagged {
            findings.append(ShakedownFinding(kind: .info, symbol: "checkmark.seal",
                text: "Nothing jumps out — this looks like a dialed kit."))
        }
        return findings
    }

    // MARK: Optional LLM narrative (system-AI gated)

    /// When system AI is available, phrases the findings as a short, friendly
    /// shakedown paragraph. Returns `nil` when unavailable so callers fall back
    /// to showing the structured findings directly.
    static func narrative(for findings: [ShakedownFinding]) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *),
           case .available = SystemLanguageModel.default.availability {
            let bullets = findings.map { "- \($0.text)" }.joined(separator: "\n")
            let prompt = """
            You are a friendly ultralight backpacking expert doing a gear "shakedown".
            Given these facts about a hiker's pack list, write 2-3 encouraging sentences
            of advice on what to cut or improve. Be specific and warm, not preachy.

            \(bullets)
            """
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                return response.content
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }
}
