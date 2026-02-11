import SwiftUI
import SwiftData

public struct Detail: View {
    let item: Item

    public var body: some View {
        List {
            Section {
                Text(item.name ?? "Unbenannt")
                Text(item.number ?? "-")
            }

            Section {
                Text(String(item.quantity ?? 0))
                HStack { Text("Mindestbestand") ; Spacer() ; Text(item.minQuantity != nil ? String(item.minQuantity!) : "-") }
                Text(item.location ?? "Lagerplatz unbekannt")
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
