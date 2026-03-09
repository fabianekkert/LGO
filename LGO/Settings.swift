import SwiftUI

public struct Settings: View {
    @AppStorage("serverAdresse") private var serverAdresse = "192.168.2.172:8000"
    @EnvironmentObject private var auth: AuthVerwaltung

    @State private var benutzer: [BenutzerOut] = []
    @State private var bearbeiteteNamen: [Int: String] = [:]
    @State private var bearbeitetePasswoerter: [Int: String] = [:]
    @State private var aufgeklappterBenutzer: Int?
    @State private var ladefehler: String?

    public init() {}

    public var body: some View {
        VStack {
            Spacer()
            Spacer()
            List {
                Label("Exportieren", systemImage: "square.and.arrow.up")
                Label("Sprache einstellen", systemImage: "globe")
                HStack {
                    Label("IP-Adresse", systemImage: "cloud")
                    Spacer()
                    TextField("IP:Port", text: $serverAdresse)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                // Nutzer verwalten — nur für Admins
                if auth.rolle == "admin" {
                    Section(header: Text("Nutzer verwalten")) {
                        if benutzer.isEmpty && ladefehler == nil {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        if let ladefehler {
                            Text(ladefehler)
                                .foregroundStyle(.red)
                        }

                        ForEach(benutzer) { nutzer in
                            DisclosureGroup(
                                isExpanded: bindingFuer(nutzerID: nutzer.id)
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Benutzername")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        TextField("Benutzername", text: bindingName(fuer: nutzer))
                                            .multilineTextAlignment(.trailing)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    }

                                    HStack {
                                        Text("Passwort")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        SecureField("Neues Passwort", text: bindingPasswort(fuer: nutzer))
                                            .multilineTextAlignment(.trailing)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    }

                                    HStack {
                                        Text("Rolle")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(nutzer.rolle.capitalized)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            } label: {
                                Label(nutzer.benutzername, systemImage: nutzer.rolle == "admin" ? "person.badge.key" : "person")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .task {
                if auth.rolle == "admin" {
                    await benutzerVomServerLaden()
                }
            }
        }
    }

    // MARK: - Daten laden

    private func benutzerVomServerLaden() async {
        do {
            benutzer = try await auth.benutzerLaden()
            // Initiale Werte setzen
            for b in benutzer {
                bearbeiteteNamen[b.id] = b.benutzername
                bearbeitetePasswoerter[b.id] = ""
            }
            ladefehler = nil
        } catch {
            ladefehler = error.localizedDescription
        }
    }

    // MARK: - Bindings

    private func bindingFuer(nutzerID: Int) -> Binding<Bool> {
        Binding(
            get: { aufgeklappterBenutzer == nutzerID },
            set: { aufgeklappterBenutzer = $0 ? nutzerID : nil }
        )
    }

    private func bindingName(fuer nutzer: BenutzerOut) -> Binding<String> {
        Binding(
            get: { bearbeiteteNamen[nutzer.id] ?? nutzer.benutzername },
            set: { bearbeiteteNamen[nutzer.id] = $0 }
        )
    }

    private func bindingPasswort(fuer nutzer: BenutzerOut) -> Binding<String> {
        Binding(
            get: { bearbeitetePasswoerter[nutzer.id] ?? "" },
            set: { bearbeitetePasswoerter[nutzer.id] = $0 }
        )
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Settings()
                .environmentObject(AuthVerwaltung())
        }
    }
}
