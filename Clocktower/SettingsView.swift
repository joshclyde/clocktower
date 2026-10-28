import SwiftUI

struct SettingsView: View {
    @Environment(ChimeController.self) private var controller

    private var settings: ChimeSettings { controller.settings }
    private let notificationSettingsURL = URL(string: UIApplication.openNotificationSettingsURLString)!
    private var notificationsOn: Bool {
        controller.authorization != .denied && controller.authorization != .notDetermined
    }

    var body: some View {
        NavigationStack {
            Form {
                if controller.authorization == .denied {
                    Section {
                        Label("Notifications are off for Clocktower.", systemImage: "exclamationmark.triangle")
                        Link("Open Settings", destination: notificationSettingsURL)
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

                if notificationsOn {
                    Section("Tips") {
                        Label("Notifications are on for Clocktower.", systemImage: "bell.badge")
                        if controller.announcement == .enabled {
                            Label("Siri reads chimes aloud in your headphones.", systemImage: "airpods")
                        } else if controller.announcement == .disabled {
                            Label("Turn on Announce Notifications to hear chimes in your headphones.", systemImage: "speaker.wave.2")
                            Link("Open Settings", destination: notificationSettingsURL)
                        }
                    }
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
