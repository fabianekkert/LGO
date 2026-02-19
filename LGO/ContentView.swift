//  ContentView.swift
//  LGO
//  Created by Fabian on 09.02.26.

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query var items: [Item]
    @State private var sheetIsPresented = false
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationStack {
            List{
                ForEach(items) { item in
                    NavigationLink {
                        Detail(item: item)
                    } label: {
                        HStack {
                            VStack (alignment: .leading) {
                                Text(item.itemname)
                                Text(String(describing: item.itemnumber))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(describing: item.quantity))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.automatic)
            .sheet(isPresented: $sheetIsPresented) {
                NavigationStack{
                    Detail(item: Item())
                }
            }
            .padding(.vertical)
            .navigationTitle(Text("Lager"))
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
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image (systemName: "plus")
                    }
                }
            }
        }
    }
}

// Funktion um die Preview zu ermöglichen
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

