import SwiftUI
import SwiftData

struct GearListView: View {
    @Environment(GearViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @Query(sort: \GearItem.name) private var allItems: [GearItem]

    var body: some View {
        @Bindable var vm = viewModel
        List {
            ForEach(viewModel.filtered(allItems)) { item in
                ZStack {
                    NavigationLink(destination: GearItemDetailView(item: item)) { EmptyView() }
                        .opacity(0)
                    GearItemRow(item: item)
                }
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete { offsets in
                let toDelete = offsets.map { viewModel.filtered(allItems)[$0] }
                viewModel.delete(toDelete, from: context)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.trailBackground)
        .searchable(text: $vm.searchText, prompt: "Search gear")
        .navigationTitle("Gear Inventory")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    viewModel.showingAddSheet = true
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu("Sort", systemImage: "arrow.up.arrow.down") {
                    ForEach(GearSortOption.allCases) { option in
                        Button(option.rawValue) { viewModel.sortOption = option }
                    }
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu("More", systemImage: "ellipsis.circle") {
                    Button("Import from Lighterpack", systemImage: "square.and.arrow.down") {
                        viewModel.showingImportSheet = true
                    }
                    ExportButton(items: allItems)
                }
            }
        }
        .sheet(isPresented: $vm.showingAddSheet) {
            AddGearItemView()
        }
        .sheet(isPresented: $vm.showingImportSheet) {
            ImportCSVView()
        }
    }
}

private struct GearItemRow: View {
    let item: GearItem
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        HStack(spacing: 12) {
            // Category color bar + icon chip
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(item.category.color)
                .frame(width: 4)
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(item.category.color.opacity(0.16))
                    .frame(width: 38, height: 38)
                Image(systemName: item.category.symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.body.weight(.medium))
                Text(item.brand.isEmpty ? item.category.rawValue : item.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(appSettings.format(item.weightGrams))
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.trailCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.trailHairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
