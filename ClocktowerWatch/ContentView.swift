import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.badge")
                .font(.title)
                .foregroundStyle(.tint)
            Text("Clocktower")
                .font(.headline)
        }
    }
}

#Preview {
    ContentView()
}
