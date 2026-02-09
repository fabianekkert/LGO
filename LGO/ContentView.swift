//
//  ContentView.swift
//  LGO
//
//  Created by Fabian on 09.02.26.
//  

import SwiftUI
import SwiftData

// NOTE: This UI expects Item to provide optional fields used below
// name, number, quantity, minQuantity, location, and a mandatory timestamp.
// The previews create a temporary in-memory container so you can see the UI.

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    // UI State
    @State private var searchText: String = ""
    @State private var isShowingAdd: Bool = false
    @State private var sortOption: SortOption = .name
    @State private var sortAscending: Bool = true

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredAndSortedItems()) {   item in
                        NavigationLink {
                            ItemDetailView(item: item)
                        }
                        label:{
                        ItemRow(item: item)
                        }
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Lager")
            .font(.largeTitle)
            .toolbar { toolbarContent }
            .searchable(text: $searchText, placement: .automatic, prompt: Text("Suchen"))
            .sheet(isPresented: $isShowingAdd) {
                AddItemView { newItem in
                    withAnimation { modelContext.insert(newItem) }
                }
            }
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem{
            Button { isShowingAdd = true } label: {
                Label("Artikel hinzufügen", systemImage: "plus")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            
            Menu {
                
                Button { /* Einstellungen */ } label: {
                    Label("Einstellungen", systemImage: "gearshape")
                }
                Section("Sortieren") {
                    Picker("Sortieren", selection: $sortOption) {
                        Text("Name").tag(SortOption.name)
                        Text("Artikelnummer").tag(SortOption.number)
                        Text("Menge").tag(SortOption.quantity)
                    }
                    Toggle(isOn: $sortAscending) {
                        Label(sortAscending ? "Aufsteigend" : "Absteigend", systemImage: sortAscending ? "arrow.up" : "arrow.down")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Helpers
    private func filteredAndSortedItems() -> [Item] {
        var result = items
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter { item in
                let name = (item.name ?? "").lowercased()
                let number = (item.number ?? "").lowercased()
                return name.contains(q) || number.contains(q)
            }
        }
        let descriptor: (Item, Item) -> Bool
        switch sortOption {
        case .name:
            descriptor = { lhs, rhs in
                let l = lhs.name ?? ""
                let r = rhs.name ?? ""
                return sortAscending ? (l.localizedCaseInsensitiveCompare(r) == .orderedAscending) : (l.localizedCaseInsensitiveCompare(r) == .orderedDescending)
            }
        case .number:
            descriptor = { lhs, rhs in
                let l = lhs.number ?? ""
                let r = rhs.number ?? ""
                return sortAscending ? (l.localizedStandardCompare(r) == .orderedAscending) : (l.localizedStandardCompare(r) == .orderedDescending)
            }
        case .quantity:
            descriptor = { lhs, rhs in
                let l = lhs.quantity ?? 0
                let r = rhs.quantity ?? 0
                return sortAscending ? (l < r) : (l > r)
            }
        }
        return result.sorted(by: descriptor)
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let current = filteredAndSortedItems()
            for index in offsets { modelContext.delete(current[index]) }
        }
    }
}

// MARK: - Sort
private enum SortOption: Hashable { case name, number, quantity }

// MARK: - Row
private struct ItemRow: View {
    let item: Item
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "—")
                    .font(.headline)
                Text(item.number ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(item.quantity ?? 0)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Item View
private struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var number: String = ""
    @State private var quantity: Int = 0
    @State private var hasMin: Bool = false
    @State private var minQuantity: Double = 0
    @State private var location: String = ""

    var onCreate: (Item) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Bezeichnung", text: $name)
                    TextField("Artikelnummer", text: $number)
                }
                Section {
                    Stepper(value: $quantity, in: 0...10_000) {
                        HStack {
                            Text("Anzahl")
                            Spacer()
                            Text("\(quantity)")
                        }
                    }
                    Toggle("Mindestbestand", isOn: $hasMin)
                    if hasMin {
                        HStack {
                            Text("Mindestbestand")
                            Spacer()
                            TextField("0", value: $minQuantity, formatter: numberFormatter)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                        }
                    }
                    TextField("Lagerort", text: $location)
                }
            }
            .navigationTitle("Artikel hinzufügen")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: create) {
                        Text("Hinzufügen")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var numberFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }

    private func create() {
        var item = Item(timestamp: Date())
        item.name = name.isEmpty ? nil : name
        item.number = number.isEmpty ? nil : number
        item.quantity = quantity
        item.minQuantity = hasMin ? minQuantity : nil
        item.location = location.isEmpty ? nil : location
        onCreate(item)
        dismiss()
    }
}

// MARK: - Detail View
private struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showAdjustSheet = false

    @Bindable var item: Item

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox {
                    
                        HStack {
                            Text("Anzahl")
                            Spacer()
                            Text("\(item.quantity ?? 0)")
                        }
                    
                    Toggle("Mindestbestand", isOn: Binding(get: { (item.minQuantity ?? -1) >= 0 }, set: { enabled in
                        if !enabled { item.minQuantity = nil } else if item.minQuantity == nil { item.minQuantity = 0 }
                    }))
                    if let _ = item.minQuantity {
                        HStack {
                            Text("Mindestbestand")
                            Spacer()
                            TextField("0", value: Binding(get: { item.minQuantity ?? 0 }, set: { item.minQuantity = $0 }), formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                        }
                    }
                    TextField("Lagerort", text: Binding(get: { item.location ?? "" }, set: { item.location = $0.isEmpty ? nil : $0 }))
                }
                .groupBoxStyle(.automatic)
                .cornerRadius(15)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.quaternary)
                    .frame(height: 220)
                    .overlay(alignment: .center) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                    }

                Button("Anzahl anpassen") { showAdjustSheet = true }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 8)
            }
            .padding()
        }
        .navigationTitle(item.name ?? "Artikel")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Umbenennen") { /* future */ }
                    Button("Löschen", role: .destructive) {
                        modelContext.delete(item)
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAdjustSheet) {
            AdjustQuantitySheet(quantity: Binding(get: { item.quantity ?? 0 }, set: { item.quantity = $0 }))
                .presentationDetents([.height(180)])
        }
    }
}

// MARK: - Adjust Quantity Sheet
private struct AdjustQuantitySheet: View {
    @Binding var quantity: Int
    var body: some View {
        VStack(spacing: 16) {
            Text("Anzahl anpassen").font(.headline)
            HStack(spacing: 24) {
                Button { quantity = max(0, quantity + 1) } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 34))
                }
                Text("\(quantity)").font(.largeTitle).monospacedDigit()
                Button { quantity = max(0, quantity - 1) } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 34))
                }
            }
        }
        .padding()
    }
}

// MARK: - Previews
#Preview("Liste") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    let context = container.mainContext
    let samples: [(String, String, Int, Double?, String?)] = [
        ("Abdeckung", "999.718.506.201", 5, nil, nil),
        ("Frontscheibe", "991.218.649.001", 2, 1, nil),
        ("Führungsschiene", "987.669.546.444", 13, 2, nil),
        ("Ölabscheider", "991.123.564.012", 1, nil, nil),
        ("Scheinwerfer", "997.207.564.012", 4, 3, "A-12"),
        ("Schlauch", "928.997.123.045", 7, nil, nil),
        ("Schraube", "928.996.003.001", 4, nil, nil),
        ("Stoßdämpfer", "928.996.208.003", 128, 5, "B-03")
    ]
    for s in samples {
        var item = Item(timestamp: .now)
        item.name = s.0
        item.number = s.1
        item.quantity = s.2
        item.minQuantity = s.3
        item.location = s.4
        context.insert(item)
    }
    return ContentView()
        .modelContainer(container)
}

#Preview("Detail") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    let context = container.mainContext
    var item = Item(timestamp: .now)
    item.name = "Scheinwerfer"
    item.number = "997.207.564.012"
    item.quantity = 4
    item.minQuantity = 3
    item.location = "A-12"
    context.insert(item)
    return NavigationStack { ItemDetailView(item: item) }
        .modelContainer(container)
}

