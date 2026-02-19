//  addItem.swift
//  LGO
//  Created by Fabian on 11.02.26.
//  In dieser Datei befindet sich die Detail View. Diese Ansicht kommt auch, wenn man einen neuen Artikel anlegt.

import SwiftUI
import SwiftData

struct Detail: View {
    
    // Diese beiden Umgebungen ermöglichen die Nutzung von SwiftData und das Schließen des Screens
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Die Variablen werden nur hier verwendet (Daher auch private var). Sie werden in Zeile 76 mit den Init-Werten aus der class Item gefüllt. Bei Bestätigung in Zeile 103-122 werden die Werte in die Variablen von der class Item geschrieben und gespeichert. Eine ID wird automatisch generiert und muss daher nicht in ContentView.swift Zeile 16 zugewiesen werden.
    @Bindable var      item:            Item             // Übergebe class an @State var item
    @State private var itemname:        String = ""      // Variable für die Artikelbezeichnung
    @State private var itemnumber:      String = ""      // Variable für die Artikelnummer
    @State private var quantity:        String = ""      // Variable für die Anzahl
    @State private var minQuantityIsOn: Bool   = false   // Variable für den Schaltzustand vom Toggle Meldebestand
    @State private var minQuantity:     String = ""      // Variable für den Meldebestand
    @State private var orderdIsOn:      Bool   = false   // Variable für den Schaltzustand vom Toggle Bestellt
    @State private var location:        String = ""      // Variable für den Lagerort
    
    public var body: some View {
        List {
            Section {
                TextField("Artikelbezeichnung", text: $itemname)
                TextField("Artikelnummer", text: $itemnumber)
            }
            Section {
                HStack {
                    Text("Anzahl")
                    Spacer()
                    HStack(spacing: 8) {
                        TextField("0", text: $quantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle("Meldebestand", isOn: $minQuantityIsOn)
                if minQuantityIsOn {  // Das Textfeld wird ausgeblendet, wenn der Toggle inaktiv ist
                    HStack(spacing: 8) {
                        Spacer()
                        TextField("0", text: $minQuantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(.secondary)
                }
                Toggle("Bestellt", isOn: $orderdIsOn)
                
            }
            Section {
                HStack {
                    Text("Lagerort")
                    Spacer()
                    HStack(spacing: 8) {
                        TextField("0", text: $location)
                            .multilineTextAlignment(.trailing)
                        Spacer()
                    }
                }
                /*Image("Map")
                    .resizable()
                    .scaledToFit()
                    .listRowInsets(EdgeInsets())*/
                
            }
            .onAppear() {
                itemname = item.itemname
                itemnumber = item.itemnumber
                quantity = String(item.quantity)
                minQuantityIsOn = item.minQuantityIsOn
                minQuantity = String(item.minQuantity)
                orderdIsOn = item.orderdIsOn
                location = item.location
            }
            .navigationTitle(item.itemname)
            .navigationSubtitle(item.itemnumber)
            .navigationBarTitleDisplayMode( .inline )
            .navigationBarBackButtonHidden(true)
            
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        item.itemname = itemname
                        item.itemnumber = itemnumber
                        item.quantity = Int(quantity) ?? 0
                        item.minQuantityIsOn = minQuantityIsOn
                        item.minQuantity = Int(minQuantity) ?? 0
                        item.orderdIsOn = orderdIsOn
                        item.location = location
                        modelContext.insert(item)
                        guard let _ = try? modelContext.save() else {
                            print("ERROR: Save on Detail did not work")
                            return
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
                
#endif
            }
        }
    }
}

// Funktion um die Preview zu ermöglichen
#Preview {
    NavigationStack{
        Detail(item: Item())
            .modelContainer(for: Item.self, inMemory: true)
    }
}

