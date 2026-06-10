import Foundation

struct WeightParser {

    static func parseToGrams(_ raw: String) -> Double? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let g = parseDualFormat(s) { return g }
        if let g = parseGramsOnly(s) { return g }
        if let g = parsePoundsAndOunces(s) { return g }
        if let g = parseOuncesOnly(s) { return g }
        if let g = parsePoundsOnly(s) { return g }
        if let g = parseKilogramsOnly(s) { return g }
        return nil
    }

    // "4 oz / 113g", "4 oz (113 g)", "19.0 oz (539 g)", "5 ounces (140 g)"
    private static func parseDualFormat(_ s: String) -> Double? {
        let hasOz = s.range(of: #"oz|ounce"#, options: [.regularExpression, .caseInsensitive]) != nil
        let gPattern = #"(\d+(?:\.\d+)?)\s*g(?:ram[s]?)?\b"#
        guard hasOz,
              let regex = try? NSRegularExpression(pattern: gPattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let range = Range(match.range(at: 1), in: s),
              let grams = Double(String(s[range])) else { return nil }
        return grams
    }

    // "119g", "119 g", "539 grams"
    private static func parseGramsOnly(_ s: String) -> Double? {
        guard s.range(of: #"oz|ounce"#, options: [.regularExpression, .caseInsensitive]) == nil else { return nil }
        let pattern = #"^(\d+(?:\.\d+)?)\s*g(?:ram[s]?)?\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let range = Range(match.range(at: 1), in: s),
              let grams = Double(String(s[range])) else { return nil }
        return grams
    }

    // "1 lb 4 oz", "3 lbs. 14 oz."
    private static func parsePoundsAndOunces(_ s: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)\s*lbs?\.?\s+(\d+(?:\.\d+)?)\s*oz"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let lbRange = Range(match.range(at: 1), in: s),
              let ozRange = Range(match.range(at: 2), in: s),
              let lbs = Double(String(s[lbRange])),
              let oz = Double(String(s[ozRange])) else { return nil }
        return (lbs * 453.592) + (oz * 28.3495)
    }

    // "4.2 oz", "4 ounces"
    private static func parseOuncesOnly(_ s: String) -> Double? {
        guard s.range(of: #"lbs?"#, options: [.regularExpression, .caseInsensitive]) == nil else { return nil }
        let pattern = #"(\d+(?:\.\d+)?)\s*(?:oz|ounce[s]?)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let range = Range(match.range(at: 1), in: s),
              let oz = Double(String(s[range])) else { return nil }
        return oz * 28.3495
    }

    // "0.26 lbs", "1 lb"
    private static func parsePoundsOnly(_ s: String) -> Double? {
        guard s.range(of: "oz", options: .caseInsensitive) == nil else { return nil }
        let pattern = #"(\d+(?:\.\d+)?)\s*lbs?\.?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let range = Range(match.range(at: 1), in: s),
              let lbs = Double(String(s[range])) else { return nil }
        return lbs * 453.592
    }

    // "1.31 kg", "0.85 kg"
    private static func parseKilogramsOnly(_ s: String) -> Double? {
        guard s.range(of: "oz", options: .caseInsensitive) == nil,
              s.range(of: #"lbs?"#, options: [.regularExpression, .caseInsensitive]) == nil else { return nil }
        let pattern = #"(\d+(?:\.\d+)?)\s*kg\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let range = Range(match.range(at: 1), in: s),
              let kg = Double(String(s[range])) else { return nil }
        return kg * 1000
    }

    static func displayString(_ grams: Double) -> String {
        let oz = grams / 28.3495
        if grams < 28.35 {
            return String(format: "%.0fg", grams)
        } else if grams < 453.59 {
            return String(format: "%.1f oz (%.0fg)", oz, grams)
        } else {
            let lbs = grams / 453.592
            return String(format: "%.2f lbs (%.0fg)", lbs, grams)
        }
    }
}
