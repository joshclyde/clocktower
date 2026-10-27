import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Clocktower")
                .font(.largeTitle.bold())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
