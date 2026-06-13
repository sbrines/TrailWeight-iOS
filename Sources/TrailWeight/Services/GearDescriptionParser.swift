import Foundation

/// Structured fields pulled from a free-text gear description.
struct ParsedGearDescription {
    var name: String
    var weightGrams: Double?
    var category: GearCategory?
}

/// Turns a free-text description like "12 oz Patagonia Nano Puff jacket" into
/// structured fields, fully on-device: weight via `WeightParser`, category via
/// `GearCategoryClassifier`, and a cleaned name with the weight token removed.
/// Discovers nothing it isn't told — the weight must be present in the text.
enum GearDescriptionParser {

    /// A weight token, allowing a pounds+ounces pair (e.g. "1 lb 4 oz").
    private static let weightTokenPattern =
        #"\d+(?:\.\d+)?\s*(?:grams?|g|kilograms?|kg|ounces?|oz|pounds?|lbs?|lb)\b\.?"#
        + #"(?:\s+\d+(?:\.\d+)?\s*(?:ounces?|oz)\b\.?)?"#

    static func parse(_ text: String) -> ParsedGearDescription {
        // Parse only the isolated weight token so embedded numbers in a product
        // name (e.g. "NB10000") don't get mistaken for a weight.
        let grams = text.range(of: weightTokenPattern, options: [.regularExpression, .caseInsensitive])
            .flatMap { WeightParser.parseToGrams(String(text[$0])) }
        return ParsedGearDescription(
            name: cleanedName(from: text),
            weightGrams: grams,
            category: GearCategoryClassifier.shared.classify(name: text)
        )
    }

    /// Strips weight tokens (e.g. "12 oz", "340g", "1 lb 4 oz") and tidies
    /// leftover separators so the remainder reads as a product name.
    static func cleanedName(from text: String) -> String {
        let weightPattern = #"\b\d+(\.\d+)?\s*(grams?|g|kilograms?|kg|ounces?|oz|pounds?|lbs?|lb)\b\.?"#
        var name = text.replacingOccurrences(
            of: weightPattern, with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
        name = name.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        return name.trimmingCharacters(in: CharacterSet(charactersIn: " ,;-–—()/"))
    }

    /// A web-search URL for the description, used by the "Search the web" action
    /// to bridge to the existing URL importer when a weight isn't in the text.
    static func searchURL(for text: String) -> URL? {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        return URL(string: "https://duckduckgo.com/?q=\(encoded)+weight+specs")
    }
}
