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
            NavigationStack {
                ContentView()
            }
            .environmentObject(auth)
            .overlay {
                if auth.token == nil {
                    ZStack {
                        Rectangle()
                            .fill(.background)
                            .ignoresSafeArea()
                        Login(auth: auth)
                    }
                }
            }
#if os(iOS)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    auth.abmelden()
                }
            }
#elseif os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                auth.abmelden()
            }
#endif
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(auth)
    }
    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
        Schluesselbund.loeschen()
    }
}

