//  LGOApp.swift
//  LGO
//  Created by Fabian on 09.02.26.
//

import SwiftUI
import SwiftData

@main
struct LGOApp: App {
    
    @Environment(\.modelContext) var modelContext
    
    var body: some Scene {
        WindowGroup {
            Login() //Startseite: Nimmt noch nicht den ganzen Screen ein. Login fertigstellen!
            ContentView()
                .modelContainer(for: Item.self)
        }
    }
    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }
}

