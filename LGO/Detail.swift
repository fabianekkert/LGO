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
    
    /// Lädt die Item-Werte in die lokalen State-Variablen
    private func loadItemValues() {
        itemname = item.itemname
        itemnumber = item.itemnumber
        quantity = String(item.quantity)
        minQuantityIsOn = item.minQuantityIsOn
        minQuantity = String(item.minQuantity)
        orderdIsOn = item.orderdIsOn
        location = item.location
    }
    /// Prüft ob das Item neu ist (noch nicht in SwiftData gespeichert)
    private var isNewItem: Bool {
        item.modelContext == nil
    }
    
    /// Speichert die lokalen Werte zurück ins Item, sendet an API und persistiert lokal
    private func saveItem() async {
        item.itemname = itemname
        item.itemnumber = itemnumber
        item.quantity = Int(quantity) ?? 0
        item.minQuantityIsOn = minQuantityIsOn
        item.minQuantity = Int(minQuantity) ?? 0
        item.orderdIsOn = orderdIsOn
        item.location = location

        let artikel = Artikel(
            beschreibung: item.itemname,
            artikelnummer: item.itemnumber,
            bestand: item.quantity,
            meldebestand: item.minQuantity,
            lagerort: item.location,
            bestellt: item.orderdIsOn ? 1 : 0
        )

        do {
            if isNewItem {
                _ = try await auth.artikelErstellen(artikel)
                modelContext.insert(item)
            } else {
                _ = try await auth.artikelAktualisieren(artikel)
            }
            try modelContext.save()
            dismiss()
        } catch {
            print("API Fehler:", error)
        }
    }
    /// Löscht das Item lokal und auf dem Server und schließt die Ansicht
    private func deleteItem() {
        Task {
            do {
                try await auth.artikelLoeschen(artikelnummer: item.itemnumber)
            } catch {
                print("API Lösch-Fehler:", error)
            }
            modelContext.delete(item)
            guard let _ = try? modelContext.save() else {
                print("ERROR: Delete on Detail did not work")
                return
            }
            showDeleteConfirmation = false
            dismiss()
        }
    }
// MARK: - Subviews
    /// Wiederverwendbare Stepper-Zeile mit Plus/Minus-Buttons und Textfeld
    private func stepperRow(value: Binding<String>, label: String? = nil, enabled: Bool = true, tintMinus: Color = .red, tintPlus: Color = .green) -> some View {
        HStack {
            if let label { Text(label) }
            Spacer()
            Button {
                let current = Int(value.wrappedValue) ?? 0
                value.wrappedValue = String(max(0, current - 1))
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(enabled ? tintMinus : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
            TextField("0", text: value)
                .labelsHidden()
                .multilineTextAlignment(.center)
                .frame(width: 50)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .disabled(!enabled)
            Button {
                let current = Int(value.wrappedValue) ?? 0
                value.wrappedValue = String(current + 1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(enabled ? tintPlus : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
        }
    }
    /// Meldebestand-Section mit aufklappbarem Stepper
    private var minQuantitySection: some View {
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
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
            .buttonStyle(.plain)
            
            if minQuantityExpanded {
                stepperRow(value: $minQuantity, enabled: minQuantityIsOn)
            }
        }
    }
    /// Lösch-Bestätigungsdialog als Overlay
    private var deleteConfirmationOverlay: some View {
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
                        deleteItem()
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
// MARK: - Body
    @ViewBuilder
    private var formContent: some View {
        Section {
            TextField("Artikelbezeichnung", text: $itemname)
            TextField("Artikelnummer", text: $itemnumber)
        }
        Section {
            stepperRow(value: $quantity, label: "Anzahl")
            Toggle("Bestellt", isOn: $orderdIsOn)
                .toggleStyle(.switch)
        }
        minQuantitySection
        Section {
            HStack(alignment: .firstTextBaseline) {
                Text("Lagerort")
                Spacer()
                ZStack(alignment: .trailing) {
                    if location.isEmpty {
                        Text("Position")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 200, alignment: .trailing)
                            .contentTransition(.opacity)
                    }
                    TextField("", text: $location)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 200, alignment: .trailing)
                        .autocorrectionDisabled(true)
#if os(iOS)
                        .textInputAutocapitalization(.never)
#endif
                }
                .frame(minWidth: 80, maxWidth: 200, alignment: .trailing)
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
    public var body: some View {
#if os(iOS)
        ZStack {
            List {
                formContent
            }
            .listStyle(.insetGrouped)
        }
        .onAppear { loadItemValues() }
        .navigationTitle(item.itemname)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await saveItem() }
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
        .overlay {
            if showDeleteConfirmation { deleteConfirmationOverlay }
        }
#else
        ZStack {
            Form {
                formContent
            }
            .formStyle(.grouped)
        }
        .onAppear { loadItemValues() }
        .navigationTitle(item.itemname)
        .navigationSubtitle(item.itemnumber)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
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
                            lagerort: item.location,
                            bestellt: item.orderdIsOn ? 1 : 0
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
                    Task { await saveItem() }
                }
            }
#endif
        }
        .overlay {
            if showDeleteConfirmation { deleteConfirmationOverlay }
        }
#endif
    }
}

#Preview {
    NavigationStack{
        Detail(item: Item())
            .environmentObject(AuthVerwaltung())
            .modelContainer(for: Item.self, inMemory: true)
    }
}

