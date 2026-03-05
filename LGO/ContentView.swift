import CodeScanner
import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @Query var items: [Item]
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var auth: AuthVerwaltung
#if os(macOS)
    @Environment(\.openWindow) private var openWindow
#endif
    @State private var scannedItem: Item?
    @State private var searchText              = ""
    @State private var sheetIsPresented        = false
    @State private var isShowingScanner        = false
    @State private var showScannedItemDetail   = false
    @State private var currentSort: SortOption = .alphabetical
    /// Sortier-Optionen
    enum SortOption: String, CaseIterable {
        case alphabetical = "Bezeichnung"
        case byNumber     = "Nummer"
    }
    /// Artikellabel in der Liste
    private struct ItemRow:     View  {
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
    private var sortedItems:   [Item] {
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
    private var orderedItems:  [Item] {
        sortedItems.filter { $0.orderdIsOn }
    }
    private var normalItems:   [Item] {
        sortedItems.filter { !$0.orderdIsOn && !($0.minQuantityIsOn && $0.quantity <= $0.minQuantity) }
    }
    /// Anzeige nach Sortierung
    private var visibleItems:  [Item] { sortedItems }
    /// Sections-Inhalt — wird von beiden Plattformen verwendet
    @ViewBuilder
    private var itemSections: some View {
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
    /// Gemeinsame Modifier für die Liste
    private func applyCommonModifiers<V: View>(_ view: V) -> some View {
        view
            .overlay {  /// Wenn Liste Leer
                if visibleItems.isEmpty {
                    ContentUnavailableView(
                        "Keine Artikel",
                        systemImage: "shippingbox",
                        description: Text("Lege einen neuen Artikel an.")
                    )
                }
            }
            .navigationTitle(auth.token == nil ? "" : "Lager")
            .navigationSubtitle(auth.token == nil ? "" : "\(visibleItems.count) " + (visibleItems.count == 1 ? "Eintrag" : "Einträge"))
            .toolbar(auth.token == nil ? .hidden : .automatic)
            .navigationDestination(isPresented: $showScannedItemDetail) {
                if let item = scannedItem {
                    Detail(item: item)
                }
            }
    }
    /// Gemeinsame Liste — wird von beiden Plattformen verwendet
    private var itemList: some View {
#if os(iOS)
        applyCommonModifiers(
            List {
                itemSections
            }
            .listStyle(.insetGrouped)
            .sheet(isPresented: $sheetIsPresented) {    /// Sheet für neuen Artikel
                NavigationStack {
                    Detail(item: Item())
                        .navigationTitle("Neuer Artikel")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        )
#else
        applyCommonModifiers(
            Form {
                itemSections
            }
            .formStyle(.grouped)
        )
#endif
    }
#if os(iOS)
    /// Scannereinstellungen und Vergleich mit den Einträgen aus der Liste
    func handleScan(result: Result<ScanResult, ScanError>) {
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
#endif
    /// Artikel vom Server laden und in SwiftData synchronisieren
    private func artikelVomServerLaden() {
        Task {
            do {
                let serverArtikel = try await auth.artikelLaden()
                for artikel in serverArtikel {
                    /// Prüfen ob Artikel bereits lokal existiert
                    let nummer = artikel.artikelnummer
                    let predicate = #Predicate<Item> { $0.itemnumber == nummer }
                    let descriptor = FetchDescriptor<Item>(predicate: predicate)
                    let vorhandene = try modelContext.fetch(descriptor)
                    
                    if let vorhandener = vorhandene.first {
                        /// Vorhandenen Artikel aktualisieren
                        vorhandener.itemname = artikel.beschreibung ?? artikel.artikelnummer
                        vorhandener.quantity = artikel.bestand
                        vorhandener.minQuantity = artikel.meldebestand
                        vorhandener.minQuantityIsOn = artikel.meldebestand > 0
                        vorhandener.location = artikel.lagerort
                    } else {
                        /// Neuen Artikel anlegen
                        let neuesItem = Item(
                            itemname: artikel.beschreibung ?? artikel.artikelnummer,
                            itemnumber: artikel.artikelnummer,
                            quantity: artikel.bestand,
                            minQuantityIsOn: artikel.meldebestand > 0,
                            minQuantity: artikel.meldebestand,
                            location: artikel.lagerort
                        )
                        modelContext.insert(neuesItem)
                    }
                }
                try modelContext.save()
            } catch {
                print("Fehler beim Laden der Artikel: \(error.localizedDescription)")
            }
        }
    }
    /// Ansicht
    var body: some View {
#if os(iOS)
        itemList
            .sheet(isPresented: $isShowingScanner) {    /// Scanner (iOS)
                CodeScannerView(
                    codeTypes: [.qr],
                    simulatedData: "Schraube M10",
                    completion: handleScan
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {   /// Item hinzufügen
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
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
                        Section {
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
            }
            .background(Color(.systemGroupedBackground))
            .onAppear { artikelVomServerLaden() }
#else
        itemList
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem(placement: .automatic) {   /// Item hinzufügen
                    Button {
                        openWindow(id: "new-item")
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .automatic) {   /// Sortierung
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                currentSort = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if currentSort == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Sortierung", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .automatic) {   /// Einstellungen
                    NavigationLink {
                        Settings()
                    } label: {
                        Label("Einstellungen", systemImage: "gear")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Suchen")
            .onAppear { artikelVomServerLaden() }
#endif
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
    .environmentObject(AuthVerwaltung())
    .modelContainer(for: Item.self, inMemory: true)
}
