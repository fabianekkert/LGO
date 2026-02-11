//
//  ContentView.swift
//  LGO
//
//  Created by Fabian on 09.02.26.
//  

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        
        NavigationSplitView {
           
            ZStack {
                
                 List {
                     ForEach(items) { item in
                         NavigationLink {
                             Detail(item: item)
                         } label: {
                             HStack {
                                 VStack(alignment: .leading) {
                                     Text(item.name ?? "Unbenannt")
                                         .font(.title3)
                                     Text(item.number ?? "-")
                                         .font(.caption)
                                         .foregroundColor(.secondary)
                                 }
                                 .frame(maxWidth: .infinity, alignment: .leading)

                                 Spacer()

                                 Text(String(item.quantity ?? 0))
                                     .frame(width: 40, height: 20, alignment: .trailing)
                             }
                         }
                     }
                     //.onDelete(perform: deleteItems)
                 }
                    .padding(.vertical)
                    .navigationTitle(Text("Lager"))
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            // Navigiert zu den Einstellungen (mit Zurück-Button auf iPhone)
                            NavigationLink {
                                // Ziel: Dein SettingsView
                                Settings()
                            } label: {
                                // Label im Menü mit Zahnrad-Icon
                                Label("Einstellungen", systemImage: "gear")
                            }
                    } label: {
                        Label("Menü", systemImage: "ellipsis")
                    }
                }
#endif
                ToolbarItem {
                    // Navigiert zu addItem (mit Zurück-Button auf iPhone)
                    NavigationLink {
                        // Ziel: addItem
                        addItem()
                    } label: {/*Label in der Toolbar*/ Label("Add Item", systemImage: "plus")}
                }
            }
        } detail: {
            Text("Wähle einen Artikel")
        }
    }

            /*private func addItem() {
                withAnimation {
                    let newItem = Item(timestamp: Date())
                    modelContext.insert(newItem)
                }
            }
             */
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

// Funktion um die Preview zu ermöglichen
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

