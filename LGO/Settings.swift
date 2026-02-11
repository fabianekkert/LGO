import SwiftUI

public struct Settings: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Text("Settings")
                .padding()
        }
        .navigationTitle("Settings")
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Settings()
        }
    }
}
