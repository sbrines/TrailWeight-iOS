import SwiftUI
import SwiftData

struct AddGearItemView: View {
    @Environment(GearViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    var existingItem: GearItem? = nil

    @State private var name = ""
    @State private var brand = ""
    @State private var category: GearCategory = .other
    @State private var weightGrams = ""
    @State private var quantityOwned = 1
    @State private var isConsumable = false
    @State private var notes = ""
    @State private var urlString = ""
    @State private var imageURL = ""

    var isEditing: Bool { existingItem != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("URLs") {
                    HStack {
                        TextField("Paste product URL", text: $urlString)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if !urlString.isEmpty {
                            Button {
                                urlString = ""
                                viewModel.urlFetchError = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            Task { await fetchFromURL() }
                        } label: {
                            if viewModel.isFetchingURL {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("Import")
                                    .fontWeight(.medium)
                            }
                        }
                        .disabled(urlString.isEmpty || viewModel.isFetchingURL)
                    }
                    if let error = viewModel.urlFetchError {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                    TextField("Image URL", text: $imageURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Item Details") {
                    TextField("Name", text: $name)
                    TextField("Brand", text: $brand)
                    Picker("Category", selection: $category) {
                        ForEach(GearCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.symbolName).tag(cat)
                        }
                    }
                    Toggle("Consumable (food / fuel)", isOn: $isConsumable)
                }

                Section("Weight & Quantity") {
                    HStack {
                        TextField("Weight", text: $weightGrams)
                            .keyboardType(.decimalPad)
                        Text(appSettings.unitLabel).foregroundStyle(.secondary)
                    }
                    Stepper("Quantity: \(quantityOwned)", value: $quantityOwned, in: 1...99)
                }

                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func fetchFromURL() async {
        guard let metadata = await viewModel.fetchMetadata(from: urlString) else { return }
        if name.isEmpty { name = metadata.name }
        if let g = metadata.weightGrams, weightGrams.isEmpty {
            weightGrams = String(format: "%.0f", g)
        } else if metadata.weightGrams == nil {
            viewModel.urlFetchError = "Name imported — weight not found, enter manually."
        }
    }

    private func loadExisting() {
        guard let item = existingItem else { return }
        name = item.name
        brand = item.brand
        category = item.category
        weightGrams = String(format: "%.0f", item.weightGrams)
        quantityOwned = item.quantityOwned
        isConsumable = item.isConsumable
        notes = item.notes
        urlString = item.purchaseURL
        imageURL = item.imageURL
    }

    private func save() {
        let grams = Double(weightGrams) ?? 0
        if let item = existingItem {
            item.name = name
            item.brand = brand
            item.category = category
            item.weightGrams = grams
            item.quantityOwned = quantityOwned
            item.isConsumable = isConsumable
            item.notes = notes
            item.purchaseURL = urlString
            item.imageURL = imageURL
            item.updatedAt = Date()
        } else {
            let item = GearItem(name: name, brand: brand, category: category,
                                weightGrams: grams, quantityOwned: quantityOwned,
                                isConsumable: isConsumable, notes: notes, purchaseURL: urlString,
                                imageURL: imageURL)
            context.insert(item)
        }
        try? context.save()
        dismiss()
    }
}
