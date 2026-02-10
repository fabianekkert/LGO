//
//  addItem.swift
//  LGO
//
//  Created by Fabian on 11.02.26.
//

import SwiftUI

public struct ItemView: View {
   
    public init() {}
    public var body: some View {
        VStack {
                    Text("Bespiel")
                    .padding()
                    .toolbar {          //  Toolbar anlegen
                                        ToolbarItem(placement: .bottomBar) {
                                                    NavigationLink {
                                                       ContentView()
                                                    } label: {
                                                        Text("Artikel anlegen")         // Text im Button
                                                    }
                                                    .frame(maxWidth: .infinity)         // Breite des Button anpassen
                                            }
                    }
        }
        .navigationTitle("Artikel hinzufügen")
    }
}


struct ItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ItemView()
        }
    }
}

