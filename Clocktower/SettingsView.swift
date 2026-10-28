import SwiftUI

struct SettingsView: View {
    @Environment(ChimeController.self) private var controller

    private var settings: ChimeSettings { controller.settings }
    private let notificationSettingsURL = URL(string: UIApplication.openNotificationSettingsURLString)!

    var body: some View {
        NavigationStack {
            Form {
                if controller.authorization == .denied {
                    Section {
                        Label("Notifications are off for Clocktower.", systemImage: "exclamationmark.triangle")
                        Link("Open Settings", destination: notificationSettingsURL)
                    }
                } else if controller.announcement != .notSupported {
                    Section {
                        if controller.announcement == .enabled {
                            Label("Siri reads chimes aloud in your headphones.", systemImage: "airpods")
                        } else {
                            Label("Turn on Announce Notifications to hear chimes in your headphones.", systemImage: "speaker.wave.2")
                            Link("Open Settings", destination: notificationSettingsURL)
                        }
                    } header: {
                        Text("Read Aloud")
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
            }
            .navigationTitle("Clocktower")
        }
    }
}

#Preview {
    SettingsView()
        .environment(ChimeController())
}
