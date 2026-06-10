import Foundation

// Lighterpack CSV format:
// Item Name,Category,desc,qty,weight,unit,url,price,worn,consumable
// Compatible with lighterpack.com import/export

enum LighterpackError: LocalizedError {
    case invalidCSV(String)
    case emptyFile

    var errorDescription: String? {
        switch self {
        case .invalidCSV(let detail): return "Invalid CSV: \(detail)"
        case .emptyFile: return "The file is empty"
        }
    }
}

struct LighterpackRow {
    let name: String
    let category: String
    let description: String
    let quantity: Int
    let weightGrams: Double
    let url: String
    let worn: Bool
    let consumable: Bool
}

enum LighterpackService {

    // MARK: - Export

    static func export(items: [GearItem]) -> String {
        var lines = ["Item Name,Category,desc,qty,weight,unit,url,price,worn,consumable"]
        for item in items {
            let fields: [String] = [
                csv(item.name),
                csv(item.category.rawValue),
                csv(item.notes),
                "\(item.quantityOwned)",
                String(format: "%.2f", item.weightGrams),
                "g",
                csv(item.purchaseURL),
                "0",
                "0",
                item.isConsumable ? "1" : "0",
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func exportPackList(packList: PackList) -> String {
        let items = (packList.items ?? []).compactMap { packItem -> String? in
            guard let gear = packItem.gearItem else { return nil }
            let fields: [String] = [
                csv(gear.name),
                csv(gear.category.rawValue),
                csv(gear.notes),
                "\(packItem.packedQuantity)",
                String(format: "%.2f", gear.weightGrams),
                "g",
                csv(gear.purchaseURL),
                "0",
                packItem.isWorn ? "1" : "0",
                gear.isConsumable ? "1" : "0",
            ]
            return fields.joined(separator: ",")
        }
        var lines = ["Item Name,Category,desc,qty,weight,unit,url,price,worn,consumable"]
        lines.append(contentsOf: items)
        return lines.joined(separator: "\n")
    }

    // MARK: - Import

    static func `import`(csv: String) throws -> [LighterpackRow] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !lines.isEmpty else { throw LighterpackError.emptyFile }

        // Skip header row if present
        let dataLines = lines.first?.lowercased().contains("item name") == true
            ? Array(lines.dropFirst())
            : lines

        var rows: [LighterpackRow] = []
        for line in dataLines {
            guard !line.isEmpty else { continue }
            let fields = parseCSVLine(line)
            guard fields.count >= 5 else { continue }

            let rawWeight = Double(fields[4]) ?? 0
            let unit = fields.count > 5 ? fields[5].lowercased() : "g"
            let grams = WeightParser.parseToGrams("\(rawWeight) \(unit)") ?? rawWeight

            rows.append(LighterpackRow(
                name: fields[0],
                category: fields.count > 1 ? fields[1] : "",
                description: fields.count > 2 ? fields[2] : "",
                quantity: Int(fields[3]) ?? 1,
                weightGrams: grams,
                url: fields.count > 6 ? fields[6] : "",
                worn: fields.count > 8 && fields[8] == "1",
                consumable: fields.count > 9 && fields[9] == "1"
            ))
        }
        return rows
    }

    static func rowsToGearItems(_ rows: [LighterpackRow]) -> [GearItem] {
        rows.map { row in
            GearItem(
                name: row.name.isEmpty ? "Imported Item" : row.name,
                brand: "",
                category: matchCategory(row.category),
                weightGrams: row.weightGrams,
                quantityOwned: max(1, row.quantity),
                isConsumable: row.consumable,
                notes: row.description,
                purchaseURL: row.url
            )
        }
    }

    // MARK: - Helpers

    /// Resolve a CSV category label to a GearCategory, tolerating case differences
    /// and the cross-platform label difference where the Android app names the
    /// sleep category "Sleep System" rather than "Sleep".
    private static func matchCategory(_ raw: String) -> GearCategory {
        let s = raw.trimmingCharacters(in: .whitespaces)
        if let exact = GearCategory(rawValue: s) { return exact }
        if let ci = GearCategory.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(s) == .orderedSame
        }) { return ci }
        if s.caseInsensitiveCompare("Sleep System") == .orderedSame { return .sleep }
        return .other
    }

    private static func csv(_ s: String) -> String {
        let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
        return s.contains(",") || s.contains("\"") || s.contains("\n")
            ? "\"\(escaped)\""
            : escaped
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let c = line[i]
            if c == "\"" {
                let next = line.index(after: i)
                if inQuotes && next < line.endIndex && line[next] == "\"" {
                    current.append("\"")
                    i = line.index(after: next)
                    continue
                }
                inQuotes.toggle()
            } else if c == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(c)
            }
            i = line.index(after: i)
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }
}
