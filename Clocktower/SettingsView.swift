import SwiftUI

struct SettingsView: View {
    @Environment(ChimeController.self) private var controller

    private var settings: ChimeSettings { controller.settings }

    var body: some View {
        NavigationStack {
            Form {
                if controller.authorization == .denied {
                    Section {
                        Label("Notifications are off for Clocktower.", systemImage: "exclamationmark.triangle")
                        Link("Open Settings", destination: URL(string: UIApplication.openNotificationSettingsURLString)!)
                    }
                }

                Section {
                    Toggle(isOn: controller.binding(\.isEnabled)) {
                        Label("Chimes", systemImage: settings.isEnabled ? "bell.fill" : "bell.slash")
                    }
                }

                Section("Every") {
                    HStack {
                        ForEach(ChimeInterval.allCases) { interval in
                            ChoiceButton(title: interval.label, isSelected: settings.interval == interval) {
                                controller.update { $0.interval = interval }
                            }
                        }
                    }
                }

                Section("Message") {
                    VStack {
                        ForEach(MessageStyle.allCases) { style in
                            ChoiceButton(title: ChimeText.sample(style: style, clock: settings.clock), isSelected: settings.style == style) {
                                controller.update { $0.style = style }
                            }
                        }
                    }
                }

                Section("Clock") {
                    Picker("Clock", selection: controller.binding(\.clock)) {
                        ForEach(ClockFormat.allCases) { clock in
                            Text(clock.label).tag(clock)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle(isOn: controller.binding(\.isTimeSensitive)) {
                        Label("Time Sensitive", systemImage: "moon")
                    }
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
        .environment(ChimeController())
}
