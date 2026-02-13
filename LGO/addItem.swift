//  addItem.swift
//  LGO
//  Created by Fabian on 11.02.26.

import SwiftUI
import SwiftData

public struct addItem: View {
   
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
    
    public init() {}
    public var body: some View {
       
// Content als Liste die man Scrollen kann
           List {
                Section {
                    TextField("Bezeichnung", text: $bezeichnung)
                    TextField("Artikelnummer", text: $artikelnummer)
                }

                Section {
                    HStack {
                        Text("Anzahl")
                        Spacer()
                        HStack(spacing: 8) {
                            TextField("0", text: $anzahl)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    HStack {
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
                    HStack {
                        Text("Lagerplatz")
                        
                        HStack(spacing: 8) {
                            TextField("0", text: $lagerplatz)
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
            .listStyle(.insetGrouped) // optional für iOS-Optik
        
// Toolbar oben und unten
        
        .toolbar {          //  Toolbar anlegen
            ToolbarItem(placement: .bottomBar) {
                    Button {
                            // Zahlen sicher umwandeln
                            let qty = Int(anzahl)
                            let minQ = Int(meldebestand)

                            // Neuen Artikel anlegen und an SwiftData übergeben
                            let newItem = Item(
                                timestamp: Date(),
                                name: bezeichnung.isEmpty ? nil : bezeichnung,
                                number: artikelnummer.isEmpty ? nil : artikelnummer,
                                quantity: qty,
                                minQuantity: meldebestandAktiv ? minQ : nil,
                                location: lagerplatz.isEmpty ? nil : lagerplatz
                            )
                            modelContext.insert(newItem)

                            // Ansicht schließen
                            dismiss()
                    } label: {
                        Text("Artikel hinzufügen")
                    }
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Artikel hinzufügen")
        .navigationBarTitleDisplayMode( .inline )
    }
}

// Funktion um die Preview zu ermöglichen
struct addItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            addItem()
        }
    }
}

