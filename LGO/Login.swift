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
// MARK: - Body
    public var body: some View {
        VStack {
            Spacer()
            Text("Login")
                .font(.largeTitle.bold())
            loginFelder
            statusBereich
            weiterButton
            Spacer()
        }
    }
// MARK: - Eingabefelder
    private var loginFelder: some View {
        VStack(spacing: 12) {
            eingabeFeld("Firmen ID", text: $companyid)
            eingabeFeld("Nutzername", text: $username)
            passwortFeld
        }
    }
    /// Wiederverwendbares Textfeld mit einheitlichem Styling
    private func eingabeFeld(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .loginTextFieldStyle()
            .loginFieldFrame()
    }
    private var passwortFeld: some View {
        ZStack {
            Group {
                if isPasswordVisible {
                    TextField("Passwort", text: $passwort)
                } else {
                    SecureField("Passwort", text: $passwort)
                }
            }
            .loginTextFieldStyle()
            HStack {
                Spacer()
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain)
            }
        }
        .loginFieldFrame()
    }
// MARK: - Status (Ladeindikator & Fehler)
    @ViewBuilder
    private var statusBereich: some View {
        if istLaden {
            ProgressView().padding(.top, 10)
        }
        if let fehlertext {
            Text(fehlertext)
                .foregroundColor(.red)
                .padding(.top, 8)
                .frame(width: 300)
                .multilineTextAlignment(.center)
        }
    }
// MARK: - Weiter-Button
    private var weiterButton: some View {
        Button {
            anmelden()
        } label: {
            Text("Weiter")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .frame(width: 300, height: 44)
        .background(.tint, in: RoundedRectangle(cornerRadius: 15))
        .padding(.top, 16)
        .disabled(companyid.isEmpty || username.isEmpty || passwort.isEmpty || istLaden) /// Erst aktiv, wenn alle Felder eine Eingabe haben
    }
// MARK: - Login-Logik
    private func anmelden() {
        Task {
            fehlertext = nil
            istLaden = true

            await auth.anmelden(firmenID: companyid, benutzername: username, passwort: passwort)
            istLaden = false

            if auth.token != nil {
                print("Login OK - Token erhalten")
            } else {
                fehlertext = auth.fehlermeldung ?? "Login fehlgeschlagen"
                print("Login fehlgeschlagen:", fehlertext ?? "")
            }
        }
    }
}
// MARK: - Gemeinsame Modifier
    private extension View {
    /// Einheitliches Styling für alle Login-Textfelder (ohne Rahmen)
    func loginTextFieldStyle() -> some View {
        self
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .textContentType(.username)
            .autocorrectionDisabled(true)
#if os(iOS)
            .textInputAutocapitalization(.never)
#endif
    }

    /// Einheitlicher Rahmen für Eingabefelder
    func loginFieldFrame() -> some View {
        self
            .padding(10)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
            .frame(width: 300)
    }
}
#Preview {
    NavigationStack {
        Login(auth: AuthVerwaltung())
    }
}
