import SwiftUI

public struct Settings: View {
    public init() {}

        public var body: some View {
            
                VStack{
                        Spacer()
                        Spacer()
                        List {
                            Label("Exportieren", systemImage: "square.and.arrow.up")
                            Label("Sprache einstellen", systemImage: "globe")
                            Label("Nutzer verwalten", systemImage: "person.2.fill")
                            Label("Passwort ändern", systemImage: "lock")
                            Label("Server einrichten", systemImage: "cloud")
                        }
                        .navigationTitle("Einstellungen")
                }
            
        }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Settings()
        }
    }
}
