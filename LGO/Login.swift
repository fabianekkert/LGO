///  Login.swift
///  LGO
///  Created by Fabian on 12.02.26.
///  In dieser Datei wird der LoginScreen beschrieben.

import SwiftUI
import SwiftData

struct Login: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @EnvironmentObject           private var auth: AuthVerwaltung
    
    @State private var companyid:                String = ""
    @State private var username:          String = ""
    @State private var passwort:          String = ""
    @State private var isPasswordVisible: Bool   = false
    @State private var istLaden:          Bool   = false
    @State private var fehlertext:        String?
    
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
                        .autocapitalization(.none)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                        .frame(width: 300)
                    Spacer().frame(height: 12)
                    TextField("Nutzername", text: $username)    /// Nutzername wird in @State private var username geschrieben
                        .multilineTextAlignment(.center)
                        .textContentType(.username)
                        .autocorrectionDisabled(true)
                        .autocapitalization(.none)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                        .frame(width: 300)
                    Spacer().frame(height: 12)
                    ZStack {
                        Group {   /// Als Gruppe, weil nur einer von beiden angezeigt werden soll
                            if isPasswordVisible {    /// Togglezustand (Per Default als nicht sichtbar)
                                TextField("Passwort", text: $passwort)          /// Passwort wird in @State private var passwort geschrieben
                                    .textContentType(.password)
                                    .autocorrectionDisabled(true)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Passwort", text: $passwort)   /// Passwort wird in @State private var passwort geschrieben
                                    .textContentType(.password)
                                    .autocorrectionDisabled(true)
                                    .autocapitalization(.none)
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
                }
            }
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    Task {    /// passiert alles, wenn die Schaltfläche betätigt wird.
                        fehlertext = nil
                        istLaden = true
                        
                        auth.abmelden()
                        
                        print(" Weiter wurde gedrückt")
                        print(" Login startet...")
                        
                        dismiss()
                        await auth.anmelden(firmenID: companyid, benutzername: username, passwort: passwort) /// Siehe Communikation Zeile 130-139
                        istLaden = false   /// Durch Wertänderung wird ProgressView gestartet.
                        
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
                }
                .frame(width: 280)
                .disabled(companyid.isEmpty || username.isEmpty || passwort.isEmpty || istLaden)
            }
        }
    }
}

#Preview {
    NavigationStack {
        Login()
            .environmentObject(AuthVerwaltung())
    }
}
