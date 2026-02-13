//  Login.swift
//  LGO
//  Created by Fabian on 12.02.26.

import SwiftUI
import SwiftData

public struct Login: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
// Diese Variablen werden von den Textfeldern als Binding benötigt
    @State private var id:       String = ""
    @State private var username: String = ""
    @State private var passwort: String = ""
    @State private var isPasswordVisible: Bool = false
    
    public init() {}
    public var body: some View {
        
        VStack {
            
            Spacer()
            HStack {
                
                VStack{
                    Text("Login")
                        .font(Font.largeTitle.bold())
                    TextField("Firmen ID", text: $id)
                        .multilineTextAlignment(.center)
                        .textContentType(.username)
                        .autocorrectionDisabled(true)
                        .autocapitalization(.none)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                        .frame(width: 300)
                    Spacer().frame(height: 12)
                    TextField("Nutzername", text: $username)
                        .multilineTextAlignment(.center)
                        .textContentType(.username)
                        .autocorrectionDisabled(true)
                        .autocapitalization(.none)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                        .frame(width: 300)
                    Spacer().frame(height: 12)
                    ZStack {
                        Group {
                            if isPasswordVisible {
                                TextField("Passwort", text: $passwort)
                                    .textContentType(.password)
                                    .autocorrectionDisabled(true)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Passwort", text: $passwort)
                                    .textContentType(.password)
                                    .autocorrectionDisabled(true)
                                    .autocapitalization(.none)
                            }
                        }
                        .multilineTextAlignment(.center)
                        
                        HStack {
                            Spacer()
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                    .frame(width: 300)
                }
            }
            Spacer()
        }
        .toolbar {  // Toolbar anlegen
            
            ToolbarItem (placement: .bottomBar){Button {
                    dismiss() // Action austauschen mit abschicken an Server
                } label: {
                    Text("Weiter")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}


// Funktion um die Preview zu ermöglichen
    struct Login_Previews: PreviewProvider {
        static var previews: some View {
            NavigationStack {
                Login()
            }
        }
    }




