///  Login.swift
///  LGO
///  Created by Fabian on 12.02.26.
///  In dieser Datei wird der LoginScreen beschrieben.

import SwiftUI
import SwiftData

struct Login: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @ObservedObject var auth: AuthVerwaltung
    
    @State private var companyid:         String = ""
    @State private var username:          String = ""
    @State private var passwort:          String = ""
    @State private var fehlertext:        String?
    @State private var isPasswordVisible: Bool   = false
    @State private var istLaden:          Bool   = false
    
    public var body: some View {
        VStack {
            Spacer()
            HStack {
                VStack{
                    Text("Login")
                        .font(Font.largeTitle.bold())
                    TextField("Firmen ID", text: $companyid)    /// FirmenID wird in @State private var companyid geschrieben
                        .multilineTextAlignment(.center)
                        .textContentType(.username)
                        .autocorrectionDisabled(true)
#if os(iOS) || os(tvOS) || os(visionOS)
                        .textInputAutocapitalization(.never)
#endif
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                        .frame(width: 300)
                    Spacer().frame(height: 12)
                    TextField("Nutzername", text: $username)    /// Nutzername wird in @State private var username geschrieben
                        .multilineTextAlignment(.center)
                        .textContentType(.username)
                        .autocorrectionDisabled(true)
#if os(iOS) || os(tvOS) || os(visionOS)
                        .textInputAutocapitalization(.never)
#endif
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                        .frame(width: 300)
                    Spacer().frame(height: 12)
                    ZStack {
                        Group {   /// Als Gruppe, weil nur einer von beiden angezeigt werden soll
                            if isPasswordVisible {    /// Togglezustand (Per Default als nicht sichtbar)
                                TextField("Passwort", text: $passwort)   /// Passwort wird in @State private var passwort geschrieben
                                    .textContentType(.password)
                                    .autocorrectionDisabled(true)
#if os(iOS) || os(tvOS) || os(visionOS)
                                    .textInputAutocapitalization(.never)
#endif
                            } else {
                                SecureField("Passwort", text: $passwort)   /// Passwort wird in @State private var passwort geschrieben
                                    .textContentType(.password)
                                    .autocorrectionDisabled(true)
#if os(iOS) || os(tvOS) || os(visionOS)
                                    .textInputAutocapitalization(.never)
#endif
                            }
                        }
                        .multilineTextAlignment(.center)
                        HStack {
                            Spacer()
                            Button(action: { isPasswordVisible.toggle() }) {    /// Toggle für die Passwortanzeige: Änderd Zustand in Zeile 49-59 (if else)
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                    .frame(width: 300)
                    
                    if istLaden {   /// ProgressView startet automatisch, wenn istLaden auf true geschaltet wird
                        ProgressView().padding(.top, 10)
                    }
                    if let fehlertext {   /// Fehlertext hat den Wert "nil". Die Variable wird in Zeile 92 mit dem Fehlertext gefüllt und aus Zeile 105 geprintet
                        Text(fehlertext)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                            .frame(width: 300)
                            .multilineTextAlignment(.center)
                    }
                    Spacer().frame(height: 16)
                    Button {
                        Task {
                            fehlertext = nil
                            istLaden = true

                            auth.abmelden()

                            print(" Weiter wurde gedrückt")
                            print(" Login startet...")
                            
                            auth.token = "test"
                            
                            await auth.anmelden(firmenID: companyid, benutzername: username, passwort: passwort)
                            istLaden = false

                            if auth.token != nil {
                                print("Login OK - Token erhalten")
                                dismiss()
                            } else {
                                fehlertext = auth.fehlermeldung ?? "Login fehlgeschlagen"
                                print("Login fehlgeschlagen:", fehlertext ?? "")
                            }
                        }
                    } label: {
                        Text("Weiter")
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: 280)
                    .disabled(companyid.isEmpty || username.isEmpty || passwort.isEmpty || istLaden)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        Login(auth: AuthVerwaltung())
    }
}
