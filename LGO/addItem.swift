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
    @State private var mindestbestand: String = ""
    @State private var lagerplatz: String = ""
    @State private var meldebestandAktiv: Bool = false    // Variable für den Schaltzustand vom Toggle
    
    public init() {}
    public var body: some View {
       
// Content als Liste die man Scrollen kann
            List {
                Section {
                    TextField("Bezeichnung", text: $bezeichnung)
                    TextField("Artikelnummer", text: $artikelnummer)
                }

                Section {
                    TextField("Anzahl", text: $anzahl)
                        .keyboardType(.numberPad) // iOS: Zahlentastatur
                    HStack{
                        Text("Meldebestand")
                        Spacer()            // durch den Spacer wird der Text links- und der Toggle rechtsbündig
                        Toggle("", isOn: $meldebestandAktiv)
                            .labelsHidden() // versteckt das (leere) Label des Toggles
                    }
                    if meldebestandAktiv {  // Das Textfeld wird ausgeblendet, wenn der Toggle inaktiv ist
                        TextField("Meldebestand eingeben", text: $mindestbestand)
                            .keyboardType(.numberPad)
                    }
                    TextField("Lagerplatz", text: $lagerplatz)
                        .keyboardType(.numberPad)
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
                            let minQ = Double(mindestbestand)

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
                        Text("Artikel anlegen")
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

