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
            // Every minute, so today's schedules notice when a window has passed.
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

            onOffSection(now: now)

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
                Picker("Clock", selection: controller.binding(\.clock)) {
                    ForEach(ClockFormat.allCases) { clock in
                        Text(clock.label).tag(clock)
                    }
                }
                .pickerStyle(.segmented)
                VStack {
                    ForEach(MessageStyle.allCases) { style in
                        ChoiceButton(title: ChimeText.sample(style: style, clock: settings.clock), isSelected: settings.style == style) {
                            controller.update { $0.style = style }
                        }
                    }
                }
            }

            Section {
                Toggle(isOn: controller.binding(\.isTimeSensitive)) {
                    Label("Time Sensitive", systemImage: "moon")
                }
            } header: {
                Text("Focus")
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
                            Text("Siri can read each chime aloud while AirPods or other supported headphones are connected. In Settings → Notifications → Clocktower → Announce Notifications, turn it on for Clocktower.")
                        }
                        Link("Open Settings", destination: notificationSettingsURL)
                    }
                }
            }
        }
    }

    /// The top section: Off / On / Schedule and, while set to Schedule, today's schedules, Snooze
    /// Today, and every schedule.
    private func onOffSection(now: Date) -> some View {
        let isScheduled = settings.mode == .schedule
        let today = isScheduled ? settings.todaysSchedules(at: now, calendar: .current) : []
        let isSnoozed = settings.isSnoozed(at: now)
        // Only while a window is left today, or to end a snooze.
        let showsSnooze = isSnoozed || today.contains { !$0.hasEnded(at: now, calendar: .current) }
        var footer = ChimeText.appDescription(for: settings)
        if showsSnooze {
            footer += "\n\nSnooze Today lasts until midnight."
        }
        return Section {
            HStack {
                ForEach(ChimeMode.allCases) { mode in
                    ChoiceButton(title: mode.label, isSelected: settings.mode == mode, color: mode.color) {
                        controller.update { $0.mode = mode }
                    }
                }
            }
            if isScheduled {
                ForEach(today) { schedule in
                    TodayRow(schedule: schedule, clock: settings.clock, now: now, isSnoozed: isSnoozed)
                }
                if showsSnooze {
                    Toggle(isOn: Binding(
                        get: { isSnoozed },
                        set: { snooze in controller.update { $0.snoozeToday(snooze, at: .now, calendar: .current) } }
                    )) {
                        Label("Snooze Today", systemImage: "moon.zzz")
                    }
                }
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
            }
        } header: {
            Text("Chimes")
        } footer: {
            Text(footer)
        }
    }
}

/// One of today's schedules, for display: Snoozed while Snooze Today is on, and Done once its
/// window has passed.
private struct TodayRow: View {
    let schedule: ChimeSchedule
    let clock: ClockFormat
    let now: Date
    let isSnoozed: Bool

    var body: some View {
        let hasEnded = schedule.hasEnded(at: now, calendar: .current)
        LabeledContent {
            if isSnoozed {
                Label("Snoozed", systemImage: "moon.zzz")
            } else if hasEnded {
                Label("Done", systemImage: "checkmark.circle")
            }
        } label: {
            Label {
                VStack(alignment: .leading) {
                    Text(ChimeText.window(of: schedule, clock: clock))
                    Text("Today")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "calendar")
            }
        }
        .foregroundStyle(isSnoozed || hasEnded ? HierarchicalShapeStyle.secondary : .primary)
    }
}

/// A schedule in the Chimes section: tap to edit, with its own on/off toggle.
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
