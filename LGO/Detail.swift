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
    @State private var minQuantityExpanded: Bool = false /// Meldebestand aufgeklappt
    @State private var orderdIsOn:      Bool   = false   /// Toggle Bestellt
    @State private var location:        String = ""      /// Lagerort
    @State private var showDeleteConfirmation: Bool = false /// Bestätigungsdialog für Löschen
    
    public var body: some View {
        ZStack {
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
                        if currentValue > 0 {
                            quantity = String(currentValue - 1)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Color.red)
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
                        quantity = String(currentValue + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.green)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
                    Toggle("Bestellt", isOn: $orderdIsOn)
            }
            Section {
                Button {
                    withAnimation {
                        minQuantityExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("Meldebestand")
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(minQuantityExpanded ? 180 : 0))
                        Spacer()
                        Toggle("Aktiv", isOn: $minQuantityIsOn)
                            .labelsHidden()
                        
                    }
                }
                .buttonStyle(.plain)
                
                if minQuantityExpanded {
                    HStack {
                        Spacer()
                        Button {
                            if minQuantityIsOn {
                                let currentValue = Int(minQuantity) ?? 0
                                if currentValue > 0 {
                                    minQuantity = String(currentValue - 1)
                                }
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(minQuantityIsOn ? Color.red : Color.gray)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .disabled(!minQuantityIsOn)
                        TextField("0", text: $minQuantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .disabled(!minQuantityIsOn)
                        Button {
                            if minQuantityIsOn {
                                let currentValue = Int(minQuantity) ?? 0
                                minQuantity = String(currentValue + 1)
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(minQuantityIsOn ? Color.green : Color.gray)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .disabled(!minQuantityIsOn)
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
                MapView(location: location)
                    .listRowInsets(EdgeInsets())
            }
            Section {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Text("Artikel löschen")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.red)
                }
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
        .overlay {
            if showDeleteConfirmation {
                ZStack {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showDeleteConfirmation = false
                        }
                    VStack(spacing: 10) {
                        Text("Bist du sicher, dass du diesen Artikel löschen möchtest?")
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        VStack(spacing: 10) {
                            Button {
                                modelContext.delete(item)
                                guard let _ = try? modelContext.save() else {
                                    print("ERROR: Delete on Detail did not work")
                                    return
                                }
                                showDeleteConfirmation = false
                                dismiss()
                            } label: {
                                Text("Löschen")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(.white)
                            }
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            
                            Button {
                                showDeleteConfirmation = false
                            } label: {
                                Text("Abbrechen")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(.primary)
                            }
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                        .padding(.horizontal, 15)
                        .padding(.bottom, 15)
                    }
                    .frame(width: 270, height: 210)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .shadow(radius: 10)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showDeleteConfirmation)
            }
        }
        
    }
}

#Preview {
    NavigationStack{
        Detail(item: Item())
            .modelContainer(for: Item.self, inMemory: true)
    }
}

