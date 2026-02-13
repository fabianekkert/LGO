//
//  LGOApp.swift
//  LGO
//
//  Created by Fabian on 09.02.26.
//

import SwiftUI
import SwiftData

@main
struct LG0App: App {
    
    @StateObject private var auth = AuthVerwaltung()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
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
                RootView()
            }
            .environmentObject(auth)
        }
        .modelContainer(sharedModelContainer)
    }
}
