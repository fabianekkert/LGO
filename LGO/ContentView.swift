///  ContentView.swift
///  LGO
///  Created by Fabian on 09.02.26.

import CodeScanner
import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @Query var items: [Item]
    @Environment(\.modelContext) var modelContext
    @State private var scannedItem: Item?
    @State private var searchText              = ""
    @State private var sheetIsPresented        = false
    @State private var isShowingScanner        = false
    @State private var showScannedItemDetail   = false
    @State private var isSearchFieldExpanded   = true
    @State private var currentSort: SortOption = .alphabetical
    
    /// Sortier-Optionen
    enum SortOption: String, CaseIterable {
        case alphabetical = "Alphabetisch"
        case byNumber     = "Nach Artikelnummer"
    }
    /// Artikellabel in der Liste
    private struct ItemRow: View {
        let item: Item
        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.itemname)
                    Text(String(describing: item.itemnumber))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if item.orderdIsOn {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle().stroke(Color.orange.opacity(0.8), lineWidth: 0.5)
                        )
                        .padding(.trailing, 4)
                } else if item.minQuantityIsOn && item.quantity <= item.minQuantity {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle().stroke(Color.red.opacity(0.8), lineWidth: 0.5)
                        )
                        .padding(.trailing, 4)
                }
                Text(String(describing: item.quantity))
                    .foregroundStyle(.secondary)
            }
        }
    }
    /// Suchfunktion
    private var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.itemname.localizedCaseInsensitiveContains(searchText)
            || String(describing: $0.itemnumber).localizedCaseInsensitiveContains(searchText)
        }
    }
    /// Sortierfunktion
    private var sortedItems: [Item] {
        switch currentSort {
        case .alphabetical:
            return filteredItems.sorted { $0.itemname.localizedCompare($1.itemname) == .orderedAscending }
        case .byNumber:
            return filteredItems.sorted { $0.itemnumber < $1.itemnumber }
        }
    }
    /// Section Bedingung
    private var criticalItems: [Item] {
        sortedItems.filter { !$0.orderdIsOn && $0.minQuantityIsOn && $0.quantity <= $0.minQuantity }
    }
    private var orderedItems: [Item] {
        sortedItems.filter { $0.orderdIsOn }
    }
    private var normalItems: [Item] {
        sortedItems.filter { !$0.orderdIsOn && !($0.minQuantityIsOn && $0.quantity <= $0.minQuantity) }
    }
    /// Anzeige nach Sortierung
    private var visibleItems: [Item] { sortedItems }
    /// Ansicht
    var body: some View {
        NavigationStack {
            List {
                /// Section für unter Meldebestand
                if !criticalItems.isEmpty {
                    Section(header: Text("Unter Meldebestand").font(.subheadline)) {
                        ForEach(criticalItems) { item in
                            NavigationLink {
                                Detail(item: item)
                            } label: {
                                ItemRow(item: item)
                            }
                        }
                    }
                }
                /// Section für Bestellt
                if !orderedItems.isEmpty {
                    Section(header: Text("Bestellt").font(.subheadline)) {
                        ForEach(orderedItems) { item in
                            NavigationLink {
                                Detail(item: item)
                            } label: {
                                ItemRow(item: item)
                            }
                        }
                    }
                }
                /// Section für Lagerbestand "normal"
                if !normalItems.isEmpty {
                    Section(header: Text("Lagerbestand").font(.subheadline)) {
                        ForEach(normalItems) { item in
                            NavigationLink {
                                Detail(item: item)
                            } label: {
                                ItemRow(item: item)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .overlay {  /// Wenn Liste Leer
                if visibleItems.isEmpty {
                    ContentUnavailableView(
                        "Keine Artikel",
                        systemImage: "shippingbox",
                        description: Text("Lege einen neuen Artikel an.")
                    )
                }
            }
            .listStyle(.automatic)
            .sheet(isPresented: $sheetIsPresented) {    /// Sheet für neuen Artikel
                NavigationStack{
                    Detail(item: Item())
                        .navigationTitle("Neuer Artikel")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $isShowingScanner) {    /// Sheet für Scanneransicht
                CodeScannerView(
                    codeTypes: [.qr],
                    simulatedData: "Schraube M10",
                    completion: handleScan
                )
            }
            .navigationTitle("Lager")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationSubtitle(Text("\(visibleItems.count) " + (visibleItems.count == 1 ? "Eintrag" : "Einträge")))
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {   /// Item hinzufügen
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image (systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {   /// Menü
                    Menu {
                        NavigationLink {
                            Settings()
                        } label: {
                            Label("Einstellungen", systemImage: "gear")
                        }
                        Divider()
                        Section("Sortieren") {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    currentSort = option
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        Spacer()
                                        if currentSort == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Menü", systemImage: "ellipsis")
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {    /// Suchfunktion (links)
                    if isSearchFieldExpanded || !searchText.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            
                            TextField("Suchen", text: $searchText)
                                .textFieldStyle(.plain)
                                .frame(width: 235)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .cornerRadius(10)
                        .transition(.scale.combined(with: .opacity))
                        
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSearchFieldExpanded = true
                            }
                        } label: {
                            Label("Suchen", systemImage: "magnifyingglass")
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                ToolbarItem(placement: .bottomBar) {    /// Spacer für Trennung
                    Spacer()
                }
                ToolbarItem(placement: .bottomBar) {    /// QR Funktion (rechts)
                    Button {
                        isShowingScanner = true
                    } label: {
                        Label("QR Scan", systemImage: "qrcode.viewfinder")
                    }
                }
                
#endif
                
            }
            .background(Color(UIColor { trait in    /// Hintergrund von den Listen in Light- und Dark Mode
                trait.userInterfaceStyle == .dark
                ? UIColor.systemBackground
                : UIColor.systemGray6
            }))
            .navigationDestination(isPresented: $showScannedItemDetail) {   /// Navigiert zum gescannten Item zur bearbeitung
                if let item = scannedItem {
                    Detail(item: item)
                }
            }
        }
    }
    func handleScan(result: Result<ScanResult,ScanError>) {     /// Scannereinstellungen und vergleich mit den Einträgen aus der Liste
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let scanned = result.string.components(separatedBy: " ")
            guard scanned.count == 2 else { return }
            
            let scannedName = scanned[0]
            let scannedNumber = scanned[1]
            
            if let matchedItem = items.first(where: {
                $0.itemname == scannedName && $0.itemnumber == scannedNumber
            }) {
                scannedItem = matchedItem
                showScannedItemDetail = true
            } else {
                let newItem = Item(itemname: scannedName, itemnumber: scannedNumber)
                scannedItem = newItem
                showScannedItemDetail = true
            }
            
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
