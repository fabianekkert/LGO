import SwiftUI

public struct Settings: View {
    @AppStorage("serverAdresse") private var serverAdresse = "192.168.2.172:8000"
    @EnvironmentObject private var auth: AuthVerwaltung

    @State private var benutzer: [BenutzerOut] = []
    @State private var bearbeiteteNamen: [Int: String] = [:]
    @State private var bearbeitetePasswoerter: [Int: String] = [:]
    @State private var aufgeklappterBenutzer: Int?
    @State private var ladefehler: String?
    @State private var passwortStatus: [Int: String] = [:]

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
                        .autocorrectionDisabled()
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
#endif
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
                                            .autocorrectionDisabled()
                                    }

                                    HStack {
                                        Text("Passwort")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        SecureField("Neues Passwort", text: bindingPasswort(fuer: nutzer))
                                            .multilineTextAlignment(.trailing)
                                            .autocorrectionDisabled()
#if os(iOS)
                                            .textInputAutocapitalization(.never)
#endif
                                    }

                                    HStack {
                                        Text("Rolle")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(nutzer.rolle.capitalized)
                                            .foregroundStyle(.secondary)
                                    }

                                    if let status = passwortStatus[nutzer.id] {
                                        Text(status)
                                            .font(.caption)
                                            .foregroundStyle(status.contains("Fehler") ? .red : .green)
                                    }

                                    Button {
                                        Task {
                                            await passwortSpeichern(fuer: nutzer)
                                        }
                                    } label: {
                                        Text("Passwort speichern")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled((bearbeitetePasswoerter[nutzer.id] ?? "").count < 4)
                                }
                                .padding(.vertical, 4)
                            } label: {
                                Label(nutzer.benutzername, systemImage: nutzer.rolle == "admin" ? "person.badge.key" : "person")
                            }
                        }
                    }
                }
            }
            Section {
                Button(role: .destructive) {
                    auth.abmelden()
                } label: {
                    HStack {
                        Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                    }
                    .foregroundStyle(.red)
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

    private func passwortSpeichern(fuer nutzer: BenutzerOut) async {
        let neuesPasswort = bearbeitetePasswoerter[nutzer.id] ?? ""
        guard neuesPasswort.count >= 4 else { return }
        do {
            try await auth.passwortAendern(benutzerID: nutzer.id, neuesPasswort: neuesPasswort)
            passwortStatus[nutzer.id] = "Passwort geändert"
            bearbeitetePasswoerter[nutzer.id] = ""
        } catch {
            passwortStatus[nutzer.id] = "Fehler: \(error.localizedDescription)"
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
