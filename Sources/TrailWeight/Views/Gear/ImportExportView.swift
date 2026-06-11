import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Cross-platform export using FileDocument + .fileExporter (works on iOS and macOS)

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    var content: String

    init(content: String) { self.content = content }

    init(configuration: ReadConfiguration) throws {
        content = String(data: configuration.file.regularFileContents ?? Data(),
                         encoding: .utf8) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: content.data(using: .utf8) ?? Data())
    }
}

struct ExportButton: View {
    let items: [GearItem]
    let filename: String

    @State private var isExporting = false

    init(items: [GearItem], filename: String = "trailweight-gear") {
        self.items = items
        self.filename = filename
    }

    var body: some View {
        Button("Export to CSV", systemImage: "square.and.arrow.up") {
            isExporting = true
        }
        .fileExporter(
            isPresented: $isExporting,
            document: CSVDocument(content: LighterpackService.export(items: items)),
            contentType: .commaSeparatedText,
            defaultFilename: filename
        ) { _ in }
    }
}

struct PackListShareButton: View {
    let packList: PackList

    @State private var isExporting = false

    var body: some View {
        Button("Export Pack List", systemImage: "square.and.arrow.up") {
            isExporting = true
        }
        .fileExporter(
            isPresented: $isExporting,
            document: CSVDocument(content: LighterpackService.exportPackList(packList: packList)),
            contentType: .commaSeparatedText,
            defaultFilename: packList.name
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
        ) { _ in }
    }
}

struct ImportCSVView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var isPickingFile = false
    @State private var importedRows: [LighterpackRow] = []
    @State private var importError: String? = nil
    @State private var showPreview = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.trailPine)

                VStack(spacing: 8) {
                    Text("Import from Lighterpack")
                        .font(.title2.bold())
                    Text("Import a CSV exported from Lighterpack.com\nor any compatible app.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }

                Button("Choose CSV File", systemImage: "doc") {
                    isPickingFile = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if let error = importError {
                    Label(error, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                Spacer()
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.trailBackground)
            .navigationTitle("Import Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $isPickingFile,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    parseFile(url: url)
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
            .sheet(isPresented: $showPreview) {
                ImportPreviewView(rows: importedRows) { selectedRows in
                    commitImport(rows: selectedRows)
                }
            }
        }
    }

    private func parseFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importError = "Permission denied for this file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let csv = try String(contentsOf: url, encoding: .utf8)
            importedRows = try LighterpackService.import(csv: csv)
            importError = nil
            showPreview = !importedRows.isEmpty
            if importedRows.isEmpty { importError = "No valid items found in this file." }
        } catch {
            importError = error.localizedDescription
        }
    }

    private func commitImport(rows: [LighterpackRow]) {
        LighterpackService.rowsToGearItems(rows).forEach { context.insert($0) }
        try? context.save()
        dismiss()
    }
}

struct ImportPreviewView: View {
    let rows: [LighterpackRow]
    let onImport: ([LighterpackRow]) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    @State private var selected: Set<Int> = []

    var selectedWeight: Double {
        selected.map { rows[$0].weightGrams * Double(rows[$0].quantity) }.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            List(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 12) {
                    Image(systemName: selected.contains(index)
                          ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selected.contains(index) ? Color.trailPine : .secondary)
                        .font(.title3)
                        .onTapGesture {
                            if selected.contains(index) { selected.remove(index) }
                            else { selected.insert(index) }
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name).font(.body)
                        HStack {
                            Text(row.category.isEmpty ? "Uncategorized" : row.category)
                            Text("·")
                            Text(appSettings.format(row.weightGrams))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if row.quantity > 1 {
                        Text("×\(row.quantity)")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selected.contains(index) { selected.remove(index) }
                    else { selected.insert(index) }
                }
            }
            .navigationTitle("Preview (\(rows.count) items)")
            .trailListBackground()
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(selected.count) of \(rows.count) selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(appSettings.format(selectedWeight))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Import \(selected.count)") {
                            onImport(selected.sorted().map { rows[$0] })
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selected.isEmpty)
                    }
                    .padding()
                }
                .background(.regularMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button(selected.count == rows.count ? "Deselect All" : "Select All") {
                        if selected.count == rows.count { selected.removeAll() }
                        else { selected = Set(0..<rows.count) }
                    }
                }
            }
            .onAppear { selected = Set(0..<rows.count) }
        }
    }
}
