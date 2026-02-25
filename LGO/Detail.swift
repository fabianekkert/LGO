///  Detail.swift
///  LGO
///  Created by Fabian on 11.02.26.
///  In dieser Datei befindet sich die Detail View. Diese Ansicht kommt auch, wenn man einen neuen Artikel anlegt.

import SwiftUI
import SwiftData

struct Detail: View {
    
    /// Diese beiden Umgebungen ermöglichen die Nutzung von SwiftData und das Schließen des Screens
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    
    /// Die Variablen werden nur hier verwendet(daher auch private var). Sie werden in Zeile 73 mit den Init-Werten aus der class Item gefüllt.
    /// Bei Bestätigung in Zeile 103-122 werden die Werte in die Variablen von der class Item geschrieben und gespeichert.
    /// Eine ID wird automatisch generiert und muss daher nicht in ContentView.swift Zeile 16 zugewiesen werden.
    @Bindable var      item:            Item             /// Übergebe class an @State var item
    @State private var itemname:        String = ""      /// Artikelbezeichnung
    @State private var itemnumber:      String = ""      /// Artikelnummer
    @State private var quantity:        String = ""      /// Anzahl
    @State private var minQuantityIsOn: Bool   = false   /// Toggle Meldebestand
    @State private var minQuantity:     String = ""      /// Meldebestand
    @State private var orderdIsOn:      Bool   = false   /// Toggle Bestellt
    @State private var location:        String = ""      /// Lagerort
    
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
                    Button {
                        let currentValue = Int(quantity) ?? 0
                        quantity = String(currentValue + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.green)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    TextField("0", text: $quantity)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    Button {
                        let currentValue = Int(quantity) ?? 0
                        if currentValue > 0 {
                            quantity = String(currentValue - 1)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Color.red)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
                Toggle("Bestellt", isOn: $orderdIsOn)
            }
            Section {
                Toggle("Meldebestand", isOn: $minQuantityIsOn)
                if minQuantityIsOn {  /// Das Textfeld wird ausgeblendet, wenn der Toggle inaktiv ist
                    HStack {
                        Text("")  /// Unsichtbarer Platzhalter für korrekte Ausrichtung
                            .frame(width: 0)
                        Spacer()
                        Button {
                            let currentValue = Int(minQuantity) ?? 0
                            minQuantity = String(currentValue + 1)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.green)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        TextField("0", text: $minQuantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        Button {
                            let currentValue = Int(minQuantity) ?? 0
                            if currentValue > 0 {
                                minQuantity = String(currentValue - 1)
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(Color.red)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Section {
                HStack {
                    Text("Lagerort")
                    Spacer()
                    HStack(spacing: 8) {
                        TextField("Position", text: $location)
                            .multilineTextAlignment(.trailing)
                        Spacer()
                    }
                }
                if !location.isEmpty {
                    Image("Map")
                        .resizable()
                        .scaledToFit()
                        .listRowInsets(EdgeInsets())
                }
            }
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

#Preview {
    NavigationStack{
        Detail(item: Item())
            .modelContainer(for: Item.self, inMemory: true)
    }
}

