import SwiftUI

struct SettingsView: View {
    @Environment(WatchController.self) private var controller

    private var settings: ChimeSettings { controller.settings }

    var body: some View {
        NavigationStack {
            List {
                Toggle(isOn: controller.binding(\.isEnabled)) {
                    Label("Chimes", systemImage: settings.isEnabled ? "bell.fill" : "bell.slash")
                }

                Section("Every") {
                    LazyVGrid(columns: [GridItem(), GridItem()]) {
                        ForEach(ChimeInterval.allCases) { interval in
                            ChoiceButton(title: interval.label, isSelected: settings.interval == interval) {
                                controller.update { $0.interval = interval }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Message") {
                    VStack {
                        ForEach(MessageStyle.allCases) { style in
                            ChoiceButton(title: ChimeText.sample(style: style, clock: settings.clock), isSelected: settings.style == style) {
                                controller.update { $0.style = style }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Clock") {
                    HStack {
                        ForEach(ClockFormat.allCases) { clock in
                            ChoiceButton(title: clock.shortLabel, isSelected: settings.clock == clock) {
                                controller.update { $0.clock = clock }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    Toggle("Time Sensitive", isOn: controller.binding(\.isTimeSensitive))
                } footer: {
                    Text("Chimes come through even when a Focus is on.")
                }
            }
            .navigationTitle("Clocktower")
        }
    }
}

#Preview {
    SettingsView()
        .environment(WatchController())
}
