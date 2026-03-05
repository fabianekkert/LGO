///  Detail.swift
///  LGO
///  Created by Fabian on 11.02.26.
///  In dieser Datei befindet sich die Detail View. Diese Ansicht kommt auch, wenn man einen neuen Artikel anlegt.

import SwiftUI
import SwiftData

struct Detail: View {
    @EnvironmentObject var auth: AuthVerwaltung
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
#if os(iOS)
            List {
                formContent
            }
            .listStyle(.insetGrouped)
#else
            Form {
                formContent
            }
            .formStyle(.grouped)
#endif
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
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
#elseif os(macOS)
        .navigationSubtitle(item.itemnumber)
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
                    Task {

                        // Werte aus dem Formular ins Item schreiben
                        item.itemname = itemname
                        item.itemnumber = itemnumber
                        item.quantity = Int(quantity) ?? 0
                        item.minQuantityIsOn = minQuantityIsOn
                        item.minQuantity = Int(minQuantity) ?? 0
                        item.orderdIsOn = orderdIsOn
                        item.location = location

                        // Artikel für API erstellen
                        let artikel = Artikel(
                            beschreibung: item.itemname,
                            artikelnummer: item.itemnumber,
                            bestand: item.quantity,
                            meldebestand: item.minQuantity,
                            lagerort: item.location
                        )

                        do {
                            // API Request
                            _ = try await auth.artikelErstellen(artikel)
                            print("Artikel erfolgreich an API gesendet")    

                            // Optional: lokal speichern (SwiftData)
                            modelContext.insert(item)
                            try modelContext.save()

                            dismiss()

                        } catch {
                            print("API Fehler:", error)
                        }
                    }
                } label: {
                    Image(systemName: "checkmark")
                }
            }
#elseif os(macOS)
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Sichern") {
                    saveItem()
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
            .environmentObject(AuthVerwaltung())
            .modelContainer(for: Item.self, inMemory: true)
    }
}

