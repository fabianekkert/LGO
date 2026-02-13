//
//  RootView.swift
//  LGO
//
//  Created by Xhafer Preteni on 17.02.26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthVerwaltung

    var body: some View {
        if auth.token == nil {
            Login()
        } else {
            ContentView()
        }
    }
}
