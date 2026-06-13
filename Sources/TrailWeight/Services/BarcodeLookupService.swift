import Foundation

/// Product fields resolved from a scanned barcode.
struct BarcodeProduct {
    let name: String
    let weightGrams: Double?
    let category: GearCategory?
}

/// Looks up a scanned barcode against Open Products Facts — a free, keyless,
/// no-account community product database. Coverage is best for mainstream retail
/// items; cottage gear may not be present, in which case the lookup returns nil
/// and the user falls back to manual entry.
enum BarcodeLookupService {

    /// Parse an Open Products Facts v2 payload into gear fields. Kept separate
    /// from the network call so it can be unit-tested.
    static func parse(_ data: Data) -> BarcodeProduct? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["status"] as? Int == 1,
              let product = json["product"] as? [String: Any] else { return nil }

        let name = (product["product_name"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return nil }

        // "quantity" is a free-text spec like "120 g" or "1.2 kg".
        let quantity = product["quantity"] as? String ?? ""
        return BarcodeProduct(
            name: name,
            weightGrams: WeightParser.parseToGrams(quantity),
            category: GearCategoryClassifier.shared.classify(name: name)
        )
    }

    static func lookup(barcode: String) async -> BarcodeProduct? {
        let code = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty,
              let url = URL(string: "https://world.openproductsfacts.org/api/v2/product/\(code).json")
        else { return nil }

        var request = URLRequest(url: url)
        request.setValue("TrailWeight/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return parse(data)
        } catch {
            return nil
        }
    }
}
