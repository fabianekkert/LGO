///  LGOApp.swift
///  LGO
///  Created by Fabian on 09.02.26.

import SwiftUI
import SwiftData

@main
struct LG0App: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject               private var auth = AuthVerwaltung()
    
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
            ZStack {
                if auth.token != nil {
                    NavigationStack {
                        ContentView()
                    }
                }
                if auth.token == nil {
                    Rectangle()
                        .fill(.background)
                        .ignoresSafeArea()
                    Login(auth: auth)
                        .transition(.opacity)
                }
            }
            .animation(.default, value: auth.token == nil)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background {
                    /// App geht in den Hintergrund → hier abmelden
                    auth.abmelden()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }
}


