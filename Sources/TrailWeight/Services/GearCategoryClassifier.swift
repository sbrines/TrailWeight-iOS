import Foundation
import NaturalLanguage
#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device, fully offline gear categorizer used as a fallback during import
/// when the source CSV has no usable category. It first tries a fast keyword
/// lexicon, then falls back to NaturalLanguage word embeddings so semantic
/// near-matches ("quilt" → Sleep, "headlamp" → Electronics) resolve even when
/// the exact word isn't in the lexicon.
///
/// The seed lexicon is shared verbatim with the Android app
/// (service/GearCategoryClassifier.kt) so the deterministic core stays in
/// parity; the embedding layer is an iOS-only enhancement.
struct GearCategoryClassifier {
    static let shared = GearCategoryClassifier()

    /// Whether the device's on-device system AI (Apple Intelligence) is enabled
    /// and ready. The import assist only runs when this is true; otherwise import
    /// falls back to the original behavior (unmatched items stay "Other").
    static var isSystemAIAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    private let embedding = NLEmbedding.wordEmbedding(for: .english)

    /// Cosine-distance ceiling for accepting an embedding match (lower = closer).
    /// Tuned conservatively so weak matches stay Other rather than guessing.
    private let maxDistance: Double = 0.82

    /// Representative seed terms per category. Keep in sync with the Android app.
    static let seeds: [(GearCategory, [String])] = [
        (.shelter,     ["tent", "tarp", "shelter", "bivy", "footprint", "groundsheet", "stake", "stakes", "guyline"]),
        (.sleep,       ["sleeping", "quilt", "pad", "pillow", "underquilt", "liner", "mattress"]),
        (.clothing,    ["jacket", "shirt", "pants", "fleece", "puffy", "rain", "baselayer", "gloves", "hat", "beanie", "socks", "shorts", "down", "hoody", "vest"]),
        (.cooking,     ["stove", "pot", "pan", "fuel", "canister", "spork", "spoon", "mug", "cookset", "windscreen", "lighter", "kettle"]),
        (.navigation,  ["map", "compass", "gps", "watch", "guidebook", "altimeter"]),
        (.firstAid,    ["firstaid", "aid", "medical", "bandage", "medication", "blister", "ibuprofen", "gauze"]),
        (.hygiene,     ["toothbrush", "toothpaste", "soap", "sunscreen", "towel", "sanitizer", "trowel", "toilet", "wipes", "deodorant", "floss"]),
        (.food,        ["food", "snack", "bar", "meal", "coffee", "dinner", "breakfast", "ramen"]),
        (.water,       ["filter", "bottle", "bladder", "reservoir", "squeeze", "purifier", "tablets", "smartwater"]),
        (.electronics, ["battery", "powerbank", "charger", "cable", "headlamp", "phone", "earbuds", "camera", "cord", "adapter", "watch"]),
        (.footwear,    ["shoes", "boots", "sandals", "runners", "gaiters", "insoles", "footwear"]),
        (.tools,       ["knife", "multitool", "repair", "duct", "scissors", "sewing", "pump", "tweezers"]),
    ]

    /// Best-guess category for a free-text item name, or `nil` if nothing scores
    /// confidently (caller keeps `.other`).
    func classify(name: String, description: String = "") -> GearCategory? {
        let tokens = Self.tokenize(name + " " + description)
        guard !tokens.isEmpty else { return nil }

        // 1) Exact lexicon hit wins immediately.
        let tokenSet = Set(tokens)
        for (category, terms) in Self.seeds where !tokenSet.isDisjoint(with: terms) {
            return category
        }

        // 2) Embedding nearest-seed fallback.
        guard let embedding else { return nil }
        var best: (category: GearCategory, distance: Double)?
        for token in tokens {
            for (category, terms) in Self.seeds {
                for seed in terms {
                    let distance = embedding.distance(between: token, and: seed)
                    if let current = best {
                        if distance < current.distance { best = (category, distance) }
                    } else {
                        best = (category, distance)
                    }
                }
            }
        }
        if let best, best.distance <= maxDistance { return best.category }
        return nil
    }

    /// Lowercased alphanumeric tokens of length > 2 (drops brand noise like "2p").
    static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }
    }
}
