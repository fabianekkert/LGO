//  ContentView.swift
//  LGO
//  Created by Fabian on 09.02.26.

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query var items: [Item]
    @Environment(\.modelContext) var modelContext
    @State private var searchText = ""
    @State private var sheetIsPresented = false
    
    var body: some View {
        NavigationStack {
            List {
               ForEach(filteredItems) { item in
                    NavigationLink {
                        Detail(item: item)
                    } label: {
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
                            }
                            else if (item.quantity<=item.minQuantity) {
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
            }
            .scrollContentBackground(.hidden)
            .overlay {
                if filteredItems.isEmpty {
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
                }
            }
            .searchable(text: $searchText, placement: .automatic, prompt: "Suchen")
            .navigationTitle("Lager")
            .navigationSubtitle(Text("\(filteredItems.count) " + (filteredItems.count == 1 ? "Eintrag" : "Einträge")))
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
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
                ToolbarItem {
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image (systemName: "plus")
                    }
                }
            }
            .background(Color(UIColor { trait in
                trait.userInterfaceStyle == .dark
                ? UIColor.systemBackground     // in Dark: sehr dunkel
                : UIColor.systemGray6          // in Light: leichtes Grau für Kontrast
            }))
        }
    }
    
    private var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.itemname.localizedCaseInsensitiveContains(searchText)
            || String(describing: $0.itemnumber).localizedCaseInsensitiveContains(searchText)
        }
    }
}

// Funktion um die Preview zu ermöglichen
#Preview {
        ContentView()
            .modelContainer(for: Item.self, inMemory: true)
    }
    
