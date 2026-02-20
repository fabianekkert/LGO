//  File.swift
//  LGO
//  Created by Fabian on 10.02.26.

import Foundation
import Security
import SwiftUI
import Combine
import SwiftData

// Modelle - werden im Abschnitt Authentifizierung abgefragt
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
struct Artikel: Codable, Identifiable {
    var id:            String { artikelnummer }
    let beschreibung:  String?
    let artikelnummer: String
    let bestand:       Int
    let meldebestand:  Int
    let lagerort:      String
}
// Schlüsselbund um die Token zu Speichern
enum Schluesselbund {
    private static let service = "com.deineapp.lager"
    private static let account = "token"

    static func speichern(_ token: String) {
        let daten = Data(token.utf8)    // Wandelt den token String mit UTF-8 zu Data um.
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
// API Client
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
        return try await anfrage(pfad: "/articles", methode: "GET", body: Optional<LoginAnfrage>.none, token: token)
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
        catch { throw NetzwerkFehler.decode }
    }
}

// Authentifizierung
@MainActor  // bringt alles auf den Hauptthread
final class AuthVerwaltung: ObservableObject {      // final class um es vor vererbung und überschreibungen zu schützen
    @Published var token:         String? = Schluesselbund.laden()
    @Published var fehlermeldung: String?

    private let api = APIClient(basisURL: URL(string: "http://100.83.30.52:8000")!) // private let ist eine konstante, die nur hier sichtbar ist

    func anmelden(firmenID: String, benutzername: String, passwort: String) async { // async kann begonnen, pausiert und später fortgesetzt werden. await muss verwendet werden, bis Ergebnis verfügbar ist. Verwendet, weil Netzwerkaufruf Zeit braucht
        fehlermeldung = nil // Anmeldung nicht fehlgeschlagen
        do {
            let antwort = try await api.anmelden(firmenID: firmenID, benutzername: benutzername, passwort: passwort) // Aufruf ist async throws, weil Anfrage warten muss und Fehler auftreten können
            Schluesselbund.speichern(antwort.token) // token wird im Schlüsselbund gespeichert
            token = antwort.token   // token wird published. Weil das im @MainActor passiert geschieht das im Hauptthread und löst Update im UI aus
        } catch { // Fehlerbehandlung
            fehlermeldung = (error as? LocalizedError)?.errorDescription ?? "Login fehlgeschlagen" // Mit fehlermeldung und token kann UI aktuallisiert werden
        }
    }
    func abmelden() {
        Schluesselbund.loeschen()
        token = nil
    }
    func artikelLaden() async throws -> [Artikel] { // async = läuft asyncron,throws = kann Fehler werfen
        guard let token else { return [] }
        return try await api.artikelLaden(token: token)
    }
}

