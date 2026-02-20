//  LGOApp.swift
//  LGO
//  Created by Fabian on 09.02.26.

import SwiftUI
import SwiftData

@main
struct LG0App: App {
    @Environment(\.dismiss) private var dismiss
    @StateObject            private var auth = AuthVerwaltung()
    @State                  private var fullScreenCoverIsPresented: Bool = true
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(Item.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .fullScreenCover(isPresented: $fullScreenCoverIsPresented) {
                Login()
                    .environmentObject(auth)
            }
        }
        .modelContainer(sharedModelContainer)
    }
    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }
}


