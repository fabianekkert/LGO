///  File.swift
///  LGO
///  Created by Fabian on 10.02.26.

import Foundation
import Security
import SwiftUI
import Combine
import SwiftData

/// Modelle - werden im Abschnitt Authentifizierung abgefragt
struct LoginAnfrage: Codable {
    let firmen_id:    String
    let benutzername: String
    let passwort:     String
}
struct LoginAntwort: Codable {
    let firmen_id:    String
    let benutzername: String
    let token:        String
    let rolle:        String
}
struct BenutzerOut: Codable, Identifiable {
    let id:          Int
    let benutzername: String
    let rolle:       String
    let firmen_id:   String
}

struct PasswortAendern: Encodable {
    let neues_passwort: String
}

struct Artikel: Codable, Identifiable {
    var id:            String { artikelnummer }
    let beschreibung:  String?
    let artikelnummer: String
    let bestand:       Int
    let meldebestand:  Int
    let lagerort:      String
    let bestellt:      Int?
    enum CodingKeys: String, CodingKey {
        case artikelnummer = "artikel_nummer"
        case beschreibung
        case bestand = "anzahl"
        case meldebestand = "meldebestand"
        case lagerort = "lagernummer"
        case bestellt
    }
}
/// Schlüsselbund um die Token zu Speichern
enum Schluesselbund {
    private static let service = "com.deineapp.lager"
    private static let account = "token"

    static func speichern(_ token: String) {
        let daten = Data(token.utf8)    /// Wandelt den token String mit UTF-8 zu Data um.
        SecItemDelete([
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary)
        SecItemAdd([
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData:   daten
        ] as CFDictionary, nil)
    }
    static func laden() -> String? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching([
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ] as CFDictionary, &item)

        guard status == errSecSuccess, let daten = item as? Data else { return nil }
        return String(data: daten, encoding: .utf8)
    }
    static func loeschen() {
        SecItemDelete([
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary)
    }
}
/// API Client
enum NetzwerkFehler: LocalizedError {
    case http(Int)
    case decode
    case unbekannt

    var errorDescription: String? {
        switch self {
        case .http(let code): return "Serverfehler (HTTP \(code))"
        case .decode:         return "Antwort konnte nicht gelesen werden"
        case .unbekannt:      return "Unbekannter Fehler"
        }
    }
}

final class APIClient {
    let basisURL:  URL
    init(basisURL: URL) { self.basisURL = basisURL }
    
    func anmelden(firmenID: String, benutzername: String, passwort: String) async throws -> LoginAntwort {
        let body = LoginAnfrage(firmen_id: firmenID, benutzername: benutzername, passwort: passwort)
        return try await anfrage(pfad: "/login", methode: "POST", body: body, token: nil)
    }
    func artikelLaden(token: String) async throws -> [Artikel] {
        return try await anfrage(pfad: "/artikel", methode: "GET", body: Optional<LoginAnfrage>.none, token: token)
    }
    func benutzerLaden(token: String) async throws -> [BenutzerOut] {
        return try await anfrage(pfad: "/benutzer", methode: "GET", body: Optional<LoginAnfrage>.none, token: token)
    }
    func artikelErstellen(_ artikel: Artikel, token: String) async throws -> Artikel {
          return try await anfrage(pfad: "/artikel", methode: "POST", body: artikel, token: token)
    }
    func artikelAktualisieren(_ artikel: Artikel, token: String) async throws -> Artikel {
        let pfad = "/artikel/\(artikel.artikelnummer)"
        return try await anfrage(pfad: pfad, methode: "PUT", body: artikel, token: token)
    }
    struct OkAntwort: Decodable { let ok: Bool? }

    func passwortAendern(benutzerID: Int, neuesPasswort: String, token: String) async throws {
        let pfad = "/benutzer/\(benutzerID)/passwort"
        let _: OkAntwort = try await anfrage(pfad: pfad, methode: "PUT", body: PasswortAendern(neues_passwort: neuesPasswort), token: token)
    }

    struct DeleteAntwort: Decodable { let ok: Bool? }

        func artikelLoeschen(artikelnummer: String, token: String) async throws {
            let pfad = "/artikel/\(artikelnummer)"
            let _: DeleteAntwort = try await anfrage(pfad: pfad, methode: "DELETE", body: Optional<Int>.none, token: token)
        }
    private func anfrage<Body: Encodable, Antwort: Decodable>(
        pfad:    String,
        methode: String,
        body:    Body?,
        token:   String?
    ) async throws -> Antwort {
        let url = URL(string: pfad, relativeTo: basisURL)!
        var req = URLRequest(url: url)
        req.httpMethod = methode
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { req.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        
        let (daten, response) = try await URLSession.shared.data(for: req)
        let http = response as! HTTPURLResponse
        
        guard (200...299).contains(http.statusCode) else { throw NetzwerkFehler.http(http.statusCode) }
        
        do { return try JSONDecoder().decode(Antwort.self, from: daten) }
        catch {
            print("Decode-Fehler: \(error)")
            print("Server-Antwort: \(String(data: daten, encoding: .utf8) ?? "nicht lesbar")")
            throw NetzwerkFehler.decode
        }
    }
}

/// Authentifizierung
@MainActor                                          /// bringt alles auf den Hauptthread
final class AuthVerwaltung: ObservableObject {      /// final class um es vor vererbung und überschreibungen zu schützen
    @Published var token:         String? = Schluesselbund.laden()
    @Published var rolle:         String  = UserDefaults.standard.string(forKey: "benutzerRolle") ?? ""
    @Published var fehlermeldung: String?

    private var api: APIClient {                    /// API-Client wird dynamisch aus der gespeicherten Server-Adresse erzeugt
        let adresse = UserDefaults.standard.string(forKey: "serverAdresse") ?? "192.168.0.57:8000"
        return APIClient(basisURL: URL(string: "http://\(adresse)")!)
    }

    func anmelden(firmenID: String, benutzername: String, passwort: String) async { /// async kann begonnen, pausiert und später fortgesetzt werden. await muss verwendet werden, bis Ergebnis verfügbar ist. Verwendet, weil Netzwerkaufruf Zeit braucht
        fehlermeldung = nil                         /// Anmeldung nicht fehlgeschlagen
        do {
            let antwort = try await api.anmelden(firmenID: firmenID, benutzername: benutzername, passwort: passwort) /// Aufruf ist async throws, weil Anfrage warten muss und Fehler auftreten können
            Schluesselbund.speichern(antwort.token) /// token wird im Schlüsselbund gespeichert
            token = antwort.token                   /// token wird published. Weil das im @MainActor passiert geschieht das im Hauptthread und löst Update im UI aus
            rolle = antwort.rolle
            UserDefaults.standard.set(antwort.rolle, forKey: "benutzerRolle")
        } catch {                                   /// Fehlerbehandlung
            fehlermeldung = (error as? LocalizedError)?.errorDescription ?? "Login fehlgeschlagen" /// Mit fehlermeldung und token kann UI aktuallisiert werden
        }
    }
    func abmelden() {
        Schluesselbund.loeschen()
        token = nil
        rolle = ""
        UserDefaults.standard.removeObject(forKey: "benutzerRolle")
    }
    func artikelLaden() async throws -> [Artikel] { /// async = läuft asyncron,throws = kann Fehler werfen
        guard let token else { return [] }
        do {
            return try await api.artikelLaden(token: token)
        } catch NetzwerkFehler.http(401) {
            abmelden()
            return []
        }
    }
    func benutzerLaden() async throws -> [BenutzerOut] {
        guard let token else { return [] }
        do {
            return try await api.benutzerLaden(token: token)
        } catch NetzwerkFehler.http(401) {
            abmelden()
            return []
        }
    }
    func artikelAktualisieren(_ artikel: Artikel) async throws -> Artikel {
        guard let token else { throw NetzwerkFehler.unbekannt }
        return try await api.artikelAktualisieren(artikel, token: token)
    }
    func artikelErstellen(_ artikel: Artikel) async throws -> Artikel {
        guard let token else { throw NetzwerkFehler.unbekannt }
        return try await api.artikelErstellen(artikel, token: token)
    }
    func artikelLoeschen(artikelnummer: String) async throws {
        guard let token else { throw NetzwerkFehler.unbekannt }
        return try await api.artikelLoeschen(artikelnummer: artikelnummer, token: token)
    }
    func passwortAendern(benutzerID: Int, neuesPasswort: String) async throws {
        guard let token else { throw NetzwerkFehler.unbekannt }
        try await api.passwortAendern(benutzerID: benutzerID, neuesPasswort: neuesPasswort, token: token)
    }
}

