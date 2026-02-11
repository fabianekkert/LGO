import SwiftUI

public struct Detail: View {
    public init() {}
    
    public var body: some View {
        List {
            Section {
                Text("Bezeichnung")
                Text("Artikelnummer")
            }
            

            Section {
                Text("Anzahl")
                HStack { Text("Mindestbestand") }
                Text("Lagerplatz")
            }

            Section {
                Image("Map")
                    .resizable()
                    .scaledToFit()
                    .listRowInsets(EdgeInsets())
                
            }
        }
        .listStyle(.insetGrouped) // optional für iOS-Optik
        
        .navigationTitle("Artikel 1")
        .navigationBarTitleDisplayMode(.inline)
        .navigationSubtitle("911.515.565.251")
        
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

struct Detail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Detail()
        }
    }
}
