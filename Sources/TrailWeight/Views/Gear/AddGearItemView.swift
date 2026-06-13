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
    @State private var weightInput = ""
    @State private var quantityOwned = 1
    @State private var isConsumable = false
    @State private var notes = ""
    @State private var urlString = ""
    @State private var imageURL = ""
    @State private var suggestedCategory: GearCategory? = nil
    @State private var quickDescription = ""
    @State private var showingScanner = false
    @State private var lookingUpBarcode = false
    @Environment(\.openURL) private var openURL

    var isEditing: Bool { existingItem != nil }

    private func displayToGrams(_ value: Double) -> Double {
        switch appSettings.weightUnit {
        case .grams:     return value
        case .ounces:    return value * 28.3495
        case .kilograms: return value * 1000
        case .pounds:    return value * 453.592
        }
    }

    private func gramsToDisplay(_ grams: Double) -> Double {
        switch appSettings.weightUnit {
        case .grams:     return grams
        case .ounces:    return grams / 28.3495
        case .kilograms: return grams / 1000
        case .pounds:    return grams / 453.592
        }
    }

    private func formatGramsForInput(_ grams: Double) -> String {
        let value = gramsToDisplay(grams)
        switch appSettings.weightUnit {
        case .grams:     return String(format: "%.0f", value)
        case .ounces:    return String(format: "%.2f", value)
        case .kilograms: return String(format: "%.3f", value)
        case .pounds:    return String(format: "%.3f", value)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Describe it — e.g. \u{201C}12 oz Patagonia jacket\u{201D}",
                              text: $quickDescription, axis: .vertical)
                        .lineLimit(1...3)
                    HStack {
                        Button {
                            applyDescription()
                        } label: {
                            Label("Fill in fields", systemImage: "sparkles")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(quickDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                        Spacer()
                        Button {
                            if let url = GearDescriptionParser.searchURL(for: quickDescription) {
                                openURL(url)
                            }
                        } label: {
                            Label("Search the web", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(quickDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    #if os(iOS)
                    if #available(iOS 16.0, *), BarcodeScannerView.isSupported {
                        Button {
                            showingScanner = true
                        } label: {
                            Label(lookingUpBarcode ? "Looking up…" : "Scan barcode",
                                  systemImage: "barcode.viewfinder")
                        }
                        .disabled(lookingUpBarcode)
                    }
                    #endif
                } header: {
                    Text("Quick Add")
                } footer: {
                    Text("Fills the fields below from your description. Use Search the web to look up a weight you don't know, then paste the product URL.")
                }

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
                        .onChange(of: name) { _, _ in updateSuggestion() }
                    TextField("Brand", text: $brand)
                        .onChange(of: brand) { _, _ in updateSuggestion() }
                    Picker("Category", selection: $category) {
                        ForEach(GearCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.symbolName).tag(cat)
                        }
                    }
                    if let suggested = suggestedCategory, suggested != category {
                        Button {
                            category = suggested
                            suggestedCategory = nil
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("Suggested: \(suggested.rawValue)")
                                Spacer()
                                Text("Apply").fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.trailPine)
                        }
                    }
                    Toggle("Consumable (food / fuel)", isOn: $isConsumable)
                }

                Section("Weight & Quantity") {
                    HStack {
                        TextField("Weight", text: $weightInput)
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
            .trailListBackground()
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
            #if os(iOS)
            .sheet(isPresented: $showingScanner) {
                if #available(iOS 16.0, *) {
                    NavigationStack {
                        BarcodeScannerView { code in
                            showingScanner = false
                            lookupBarcode(code)
                        }
                        .ignoresSafeArea()
                        .navigationTitle("Scan Barcode")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showingScanner = false }
                            }
                        }
                    }
                }
            }
            #endif
        }
    }

    #if os(iOS)
    /// Look up a scanned barcode against Open Products Facts and fill empty
    /// fields. Category is applied only when system AI is available.
    private func lookupBarcode(_ code: String) {
        Task { @MainActor in
            lookingUpBarcode = true
            defer { lookingUpBarcode = false }
            guard let product = await BarcodeLookupService.lookup(barcode: code) else {
                viewModel.urlFetchError = "No product found for that barcode."
                return
            }
            if name.isEmpty { name = product.name }
            if weightInput.isEmpty, let grams = product.weightGrams {
                weightInput = formatGramsForInput(grams)
            }
            if category == .other, GearCategoryClassifier.isSystemAIAvailable,
               let productCategory = product.category {
                category = productCategory
            }
            updateSuggestion()
        }
    }
    #endif

    private func fetchFromURL() async {
        guard let metadata = await viewModel.fetchMetadata(from: urlString) else { return }
        if name.isEmpty { name = metadata.name }
        if let g = metadata.weightGrams, weightInput.isEmpty {
            weightInput = formatGramsForInput(g)
        } else if metadata.weightGrams == nil {
            viewModel.urlFetchError = "Name imported — weight not found, enter manually."
        }
        updateSuggestion()
    }

    /// Parse the free-text description and fill empty fields. Weight and name are
    /// extracted on-device; category is applied only when system AI is available.
    private func applyDescription() {
        let parsed = GearDescriptionParser.parse(quickDescription)
        if name.isEmpty { name = parsed.name }
        if weightInput.isEmpty, let grams = parsed.weightGrams {
            weightInput = formatGramsForInput(grams)
        }
        if category == .other, GearCategoryClassifier.isSystemAIAvailable,
           let parsedCategory = parsed.category {
            category = parsedCategory
        }
        updateSuggestion()
    }

    /// Offer an on-device category guess while the category is still unset.
    /// Gated on system AI, so it matches the import assist's availability rules.
    private func updateSuggestion() {
        guard !isEditing,
              category == .other,
              !name.isEmpty,
              GearCategoryClassifier.isSystemAIAvailable else {
            suggestedCategory = nil
            return
        }
        suggestedCategory = GearCategoryClassifier.shared.classify(name: name, description: brand)
    }

    private func loadExisting() {
        guard let item = existingItem else { return }
        name = item.name
        brand = item.brand
        category = item.category
        weightInput = formatGramsForInput(item.weightGrams)
        quantityOwned = item.quantityOwned
        isConsumable = item.isConsumable
        notes = item.notes
        urlString = item.purchaseURL
        imageURL = item.imageURL
    }

    private func save() {
        let displayValue = Double(weightInput) ?? 0
        let grams = displayToGrams(displayValue)
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
