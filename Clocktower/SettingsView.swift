import SwiftUI

struct SettingsView: View {
    @Environment(ChimeController.self) private var controller
    /// The schedule open in the editor sheet; new ones aren't in `settings.schedules` until added.
    @State private var editing: ChimeSchedule?

    private var settings: ChimeSettings { controller.settings }
    private let notificationSettingsURL = URL(string: UIApplication.openNotificationSettingsURLString)!
    private var notificationsOn: Bool {
        controller.authorization != .denied && controller.authorization != .notDetermined
    }

    var body: some View {
        NavigationStack {
            // Every minute, so the Today section notices when a window has passed.
            TimelineView(.everyMinute) { context in
                form(now: context.date)
            }
            .navigationTitle("Clocktower")
            .sheet(item: $editing) { schedule in
                ScheduleEditor(
                    schedule: schedule,
                    isNew: !settings.schedules.contains(where: { $0.id == schedule.id }),
                    onSave: { saved in
                        controller.update { settings in
                            if settings.schedules.contains(where: { $0.id == saved.id }) {
                                settings.updateSchedule(saved.id) { $0 = saved }
                            } else {
                                settings.schedules.append(saved)
                            }
                        }
                    },
                    onDelete: {
                        controller.update { settings in settings.schedules.removeAll { $0.id == schedule.id } }
                    }
                )
            }
        }
    }

    private func form(now: Date) -> some View {
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
            } footer: {
                Text(ChimeText.appDescription(for: settings))
            }

            Section {
                Toggle(isOn: controller.binding(\.isInfinite)) {
                    Label("Infinite", systemImage: "infinity")
                }
            } footer: {
                Text(settings.isInfinite
                    ? "Chimes all day, every day. Turn off to chime only during your schedules."
                    : "Chimes only during your schedules.")
            }

            todaySection(now: now)

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

            schedulesSection

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
                            Text("Siri can read each chime aloud while AirPods or other supported headphones are connected. In Settings → Notifications → Clocktower → Announce Notifications, turn it on for Clocktower.")
                        }
                        Link("Open Settings", destination: notificationSettingsURL)
                    }
                }
            }
        }
    }

    /// Today's schedules, each with a toggle to turn it off for the rest of the day until its window passes.
    @ViewBuilder
    private func todaySection(now: Date) -> some View {
        let schedules = settings.todaysSchedules(at: now, calendar: .current)
        if settings.isEnabled && !schedules.isEmpty {
            Section {
                ForEach(schedules) { schedule in
                    let window = ChimeText.window(of: schedule, clock: settings.clock)
                    if schedule.hasEnded(at: now, calendar: .current) {
                        let skipped = schedule.isSkipped(at: now)
                        LabeledContent(window) {
                            Label(skipped ? "Skipped" : "Done", systemImage: skipped ? "slash.circle" : "checkmark.circle")
                        }
                        .foregroundStyle(.secondary)
                    } else {
                        Toggle(window, isOn: Binding(
                            get: { !schedule.isSkipped(at: now) },
                            set: { isOn in
                                controller.update { settings in
                                    settings.updateSchedule(schedule.id) { $0.skipToday(!isOn, at: .now, calendar: .current) }
                                }
                            }
                        ))
                    }
                }
            } header: {
                Text("Today")
            } footer: {
                Text(settings.isInfinite
                    ? "Infinite is on, so schedules aren't used."
                    : "Turn a schedule off for the rest of today. It turns back on tomorrow.")
            }
            .disabled(settings.isInfinite)
        }
    }

    private var schedulesSection: some View {
        Section {
            ForEach(settings.schedules) { schedule in
                ScheduleRow(schedule: schedule, clock: settings.clock) {
                    editing = schedule
                } setEnabled: { isOn in
                    controller.update { settings in settings.updateSchedule(schedule.id) { $0.isEnabled = isOn } }
                }
            }
            .onDelete { offsets in
                controller.update { settings in settings.schedules.remove(atOffsets: offsets) }
            }
            Button {
                editing = ChimeSchedule()
            } label: {
                Label("Add Schedule", systemImage: "plus")
            }
        } header: {
            Text("Schedules")
        } footer: {
            Text(settings.isInfinite
                ? "Infinite is on, so schedules aren't used. Turn it off to chime only during your schedules."
                : "Chimes only during these windows.")
        }
    }
}

/// A schedule in the Schedules section: tap to edit, with its own on/off toggle.
private struct ScheduleRow: View {
    let schedule: ChimeSchedule
    let clock: ClockFormat
    let edit: () -> Void
    let setEnabled: (Bool) -> Void

    var body: some View {
        HStack {
            // Plain style keeps the button and the toggle in one List row independently tappable.
            Button(action: edit) {
                VStack(alignment: .leading) {
                    Text(ChimeText.window(of: schedule, clock: clock))
                    Text(ChimeText.days(schedule.weekdays))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle(ChimeText.window(of: schedule, clock: clock), isOn: Binding(get: { schedule.isEnabled }, set: setEnabled))
                .labelsHidden()
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
