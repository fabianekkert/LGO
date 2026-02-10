import SwiftUI

public struct SettingsView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Text("Settings")
                .padding()
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
