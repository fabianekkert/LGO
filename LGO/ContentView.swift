//  ContentView.swift
//  LGO
//  Created by Fabian on 09.02.26.

import CodeScanner
import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @Query var items: [Item]
    @Environment(\.modelContext) var modelContext
    @State private var searchText = ""
    @State private var sheetIsPresented      = false
    @State private var isShowingScanner      = false
    @State private var scannedItem: Item? // Speichert das gescannte Item (entweder gefunden oder neu erstellt)
    @State private var showScannedItemDetail = false // Steuert, ob die Detailansicht nach dem Scannen angezeigt werden soll

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

    private var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.itemname.localizedCaseInsensitiveContains(searchText)
            || String(describing: $0.itemnumber).localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var visibleItems: [Item] { filteredItems }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(visibleItems) { item in
                        NavigationLink {
                            Detail(item: item)
                        } label: {
                            ItemRow(item: item)
                        }
                        .swipeActions {
                            Button ("Delete", role: .destructive) {
                                modelContext.delete(item)
                                guard let _ = try? modelContext.save() else {
                                    print("ERROR: Save after .delete did not work.")
                                    return
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .overlay {
                    if visibleItems.isEmpty {
                        ContentUnavailableView(
                            "Keine Artikel",
                            systemImage: "shippingbox",
                            description: Text("Lege einen neuen Artikel an.")
                        )
                    }
                }
                .listStyle(.automatic)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 70)
                }
                Button {
                    isShowingScanner = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title2)
                        .imageScale(.large)
                        .frame(width: 30, height: 40)
                        .foregroundStyle(.black)
                    
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .glassEffect()
                .padding(.trailing, 28)
                .padding(.bottom, 4)
                .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 4)
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(
                        codeTypes: [.qr],
                        simulatedData: "Porsche 911",
                        completion: handleScan
                    )
                }
                
            }
            .sheet(isPresented: $sheetIsPresented) {
                NavigationStack{
                    Detail(item: Item())
                        .navigationTitle("Neuer Artikel")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .navigationTitle("Lager")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationSubtitle(Text("\(visibleItems.count) " + (visibleItems.count == 1 ? "Eintrag" : "Einträge")))
            .searchable(text: $searchText, placement: .automatic)
            .searchToolbarBehavior(.minimize)
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image (systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink {
                            Settings()
                        } label: {
                            Label("Einstellungen", systemImage: "gear")
                        }
                    } label: {
                        Label("Menü", systemImage: "ellipsis")
                    }
                }
                
#endif
                
            }
            .background(Color(UIColor { trait in
                trait.userInterfaceStyle == .dark
                ? UIColor.systemBackground
                : UIColor.systemGray6
            }))
            .navigationDestination(isPresented: $showScannedItemDetail) {
                if let item = scannedItem {
                    Detail(item: item)
                }
            }
        }
    }
    
    func handleScan(result: Result<ScanResult,ScanError>) {
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
