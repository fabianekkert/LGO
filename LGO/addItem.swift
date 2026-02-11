//
//  addItem.swift
//  LGO
//
//  Created by Fabian on 11.02.26.
//

import SwiftUI

public struct addItem: View {
   
    public init() {}
    public var body: some View {
       
// Content als Liste die man Scrollen kann
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
        
// Toolbar oben und unten
        
        .toolbar {          //  Toolbar anlegen
            ToolbarItem(placement: .topBarTrailing) {
                Label("Cancel", systemImage: "xmark")
            }
            ToolbarItem(placement: .bottomBar) {
                NavigationLink {
                    ContentView()
                } label: {
                    Text("Artikel anlegen")         // Text im Button
                }
                .frame(maxWidth: .infinity)         // Breite des Button anpassen
            }
        }
        .navigationTitle("Artikel hinzufügen")
        .navigationBarTitleDisplayMode( .inline )
    }
}


struct addItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            addItem()
        }
    }
}

