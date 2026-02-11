//
//  addItem.swift
//  LGO
//
//  Created by Fabian on 11.02.26.
//

import SwiftUI

public struct addItemView: View {
   
    public init() {}
    public var body: some View {
                
                List {
                    Text("Bezeichnung")
                    Text("Artikelnummer")
                }
                .foregroundColor(.secondary)
                .padding(12)
                
                

                
                List {
                    Text("Anzahl")
                        .foregroundColor(.secondary)
                    HStack {
                        Text("Mindestbestand")
                    }
                    Text("Lagerplatz")
                        .foregroundColor(.secondary)
                }
                .padding(12)
                   
                Image("Map")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            
            .padding(.horizontal)
            .padding(.vertical, 12)
        
        
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


struct addItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            addItemView()
        }
    }
}

