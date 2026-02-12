//  Detail.swift
//  LGO
//  Created by Fabian on 11.02.26.

import SwiftUI
import SwiftData

public struct Detail: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

// Diese Variablen werden von den Textfeldern als Binding benötigt
    @State private var bezeichnung: String = ""
    @State private var artikelnummer: String = ""
    @State private var anzahl: String = ""
    @State private var meldebestand: String = ""
    @State private var lagerplatz: String = ""

// Variable für den Schaltzustand vom Toggle
    @State private var meldebestandAktiv: Bool = false
    
    let item: Item

    public var body: some View {
        
// Content als Liste die man Scrollen kann
        List {
            Section {
                Text(item.name ?? "Unbenannt")
                Text(item.number ?? "-")
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Anzahl")
                    Spacer()
                    HStack(spacing: 8) {
                        Text(String(item.quantity ?? 0))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(.secondary)
                }
                HStack{
                    Text("Meldebestand")
                    Spacer()            // durch den Spacer wird der Text links- und der Toggle rechtsbündig
                    Toggle("", isOn: $meldebestandAktiv)
                        .labelsHidden() // versteckt das (leere) Label des Toggles
                }
                if meldebestandAktiv {  // Das Textfeld wird ausgeblendet, wenn der Toggle inaktiv ist
                    HStack(spacing: 8) {
                        TextField("0", text: $meldebestand)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }

            Section {
                Image("Map")
                    .resizable()
                    .scaledToFit()
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(item.name ?? "Artikel")
        .navigationBarTitleDisplayMode(.inline)
        .navigationSubtitle(item.number ?? "-")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Label("Umbenennen", systemImage: "pencil")
                    Label("Löschen", systemImage: "trash")
                        .foregroundColor(Color(.systemRed))
                } label: {
                    Label("Menü", systemImage: "ellipsis")
                }
            }
#endif
        }
    }
}

// Funktion um die Preview zu ermöglichen
struct Detail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Detail(item: Item(timestamp: Date(), name: "Scheinwerfer", number: "911.515.565.251", quantity: 5, minQuantity: 2, location: "A-12"))
        }
    }
}
