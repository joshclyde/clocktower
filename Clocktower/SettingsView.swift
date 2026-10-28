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
                Section {
                    Text(ChimeText.appDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }

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
                    LazyVGrid(columns: Array(repeating: GridItem(), count: 3)) {
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

                if notificationsOn {
                    Section("Tips") {
                        TipRow("Notifications are on for Clocktower.", systemImage: "bell.badge", isGood: true) {
                            Text("Clocktower can deliver chimes. If you turn notifications off in Settings, chimes stop until you turn them back on.")
                        }
                        if controller.announcement == .enabled {
                            TipRow("Siri reads chimes aloud in your headphones.", systemImage: "airpods", isGood: true) {
                                Text("With AirPods or other supported headphones connected, Siri reads each chime to you. To stop, turn off Announce Notifications for Clocktower in Settings.")
                            }
                            Link("Open Settings", destination: notificationSettingsURL)
                        } else if controller.announcement == .disabled {
                            TipRow("Turn on Announce Notifications to hear chimes in your headphones.", systemImage: "speaker.wave.2", isGood: false) {
                                Text("Siri can read each chime aloud while AirPods or other supported headphones are connected. In Settings → Notifications → Announce Notifications, turn it on, then turn on Clocktower.")
                            }
                            Link("Open Settings", destination: notificationSettingsURL)
                        }
                    }
                }
            }
            .navigationTitle("Clocktower")
        }
    }
}

/// A row in the Tips section: a green checkmark when the tip is already followed, and a
/// disclosure with more detail.
private struct TipRow<Details: View>: View {
    let title: String
    let systemImage: String
    let isGood: Bool
    let details: Details

    init(_ title: String, systemImage: String, isGood: Bool, @ViewBuilder details: () -> Details) {
        self.title = title
        self.systemImage = systemImage
        self.isGood = isGood
        self.details = details()
    }

    var body: some View {
        DisclosureGroup {
            details
                .font(.footnote)
                .foregroundStyle(.secondary)
        } label: {
            Label {
                Text(title)
            } icon: {
                if isGood {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    Image(systemName: systemImage)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(ChimeController())
}
