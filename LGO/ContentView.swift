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
    @State private var sheetIsPresented = false
    @State private var isShowingScanner = false

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
                } else if (item.quantity <= item.minQuantity) {
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
                ToolbarItem {
                    Button ("Scan", systemImage: "qrcode.viewfinder") {
                        isShowingScanner = true
                        
                    }
                    .sheet(isPresented: $isShowingScanner) {
                        CodeScannerView(codeTypes: [.qr],
                                        simulatedData: "Porsche 911",
                                        completion: handleScan)
                    }
                }
                ToolbarSpacer(.fixed)
                ToolbarItem {
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image (systemName: "plus")
                    }
                }
                ToolbarItem {
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
                ? UIColor.systemBackground     // in Dark: sehr dunkel
                : UIColor.systemGray6          // in Light: leichtes Grau für Kontrast
            }))
        }
    }
    
    func handleScan(result: Result<ScanResult,ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: " ")
            guard details.count == 2 else { return }
            
            let item = Item(itemname: details[0], itemnumber: details[1])
            modelContext.insert(item)
            
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
}

// Funktion um die Preview zu ermöglichen
#Preview {
        ContentView()
            .modelContainer(for: Item.self, inMemory: true)
    }
    
