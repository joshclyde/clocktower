import SwiftUI

struct SettingsView: View {
    @Environment(ChimeController.self) private var controller
    /// The schedule open in the editor sheet; new ones aren't in `settings.schedules` until added.
    @State private var editing: ChimeSchedule?
    /// The Before and After text while typing. Saved when editing ends rather than on every
    /// keystroke, since each save reschedules every chime and syncs the watch.
    @State private var messageDraft = CustomMessage()
    @FocusState private var messageField: MessageField?
    @Environment(\.scenePhase) private var scenePhase

    private enum MessageField {
        case prefix, suffix
    }

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
            .onAppear { messageDraft = settings.customMessage }
            .onChange(of: settings.customMessage) {
                if messageField == nil { messageDraft = settings.customMessage }
            }
            .onChange(of: messageField) {
                if messageField == nil { saveMessage() }
            }
            // Leaving the app doesn't end editing, so save then too.
            .onChange(of: scenePhase) {
                if scenePhase != .active { saveMessage() }
            }
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

            messageSection

            Section {
                Toggle(isOn: controller.binding(\.isTimeSensitive)) {
                    Label("Time Sensitive", systemImage: "moon")
                }
            } header: {
                Text("Focus")
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
        // Scrolling closes the keyboard, which ends editing and saves the message.
        .scrollDismissesKeyboard(.interactively)
    }

    /// The top section: Off / On / Schedule, and today's schedules while set to Schedule.
    private func onOffSection(now: Date) -> some View {
        let today = settings.mode == .schedule ? settings.todaysSchedules(at: now, calendar: .current) : []
        var footer = ChimeText.appDescription(for: settings)
        if !today.isEmpty {
            footer += "\n\nTurning off one of today's schedules lasts until midnight."
        }
        return Section {
            HStack {
                ForEach(ChimeMode.allCases) { mode in
                    ChoiceButton(title: mode.label, isSelected: settings.mode == mode, color: mode.color) {
                        controller.update { $0.mode = mode }
                    }
                }
            }
            ForEach(today) { schedule in
                TodayRow(schedule: schedule, clock: settings.clock, now: now) { skip in
                    controller.update { settings in
                        settings.updateSchedule(schedule.id) { $0.skipToday(skip, at: .now, calendar: .current) }
                    }
                }
            }
        } header: {
            Text("Chimes")
        } footer: {
            Text(footer)
        }
    }

    /// An example of the whole message (updating while typing), the clock format, and optional text
    /// before and after the time.
    private var messageSection: some View {
        Section {
            Text("Example: \(ChimeText.sample(clock: settings.clock, customMessage: messageDraft))")
                .foregroundStyle(.secondary)
            Picker("Clock", selection: controller.binding(\.clock)) {
                ForEach(ClockFormat.allCases) { clock in
                    Text(clock.label).tag(clock)
                }
            }
            .pickerStyle(.segmented)
            messageTextField("Text before the time", text: $messageDraft.prefix, field: .prefix)
            messageTextField("Text after the time", text: $messageDraft.suffix, field: .suffix)
        } header: {
            Text("Message")
        }
    }

    /// A message field with a clear button while it's being edited and has text, like Contacts.
    private func messageTextField(_ prompt: String, text: Binding<String>, field: MessageField) -> some View {
        HStack {
            TextField(prompt, text: text)
                .focused($messageField, equals: field)
                // Return closes the keyboard, which ends editing and saves the message.
                .submitLabel(.done)
            if messageField == field, !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                // Borderless keeps it tappable on its own inside the Form row.
                .buttonStyle(.borderless)
                .accessibilityLabel("Clear")
            }
        }
    }

    private func saveMessage() {
        guard messageDraft != settings.customMessage else { return }
        controller.update { $0.customMessage = messageDraft }
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
            Text(settings.mode == .schedule
                ? "Chimes only during these windows."
                : "Choose Schedule above to chime only during these windows.")
        }
    }
}

/// One of today's schedules: a toggle that turns it off until midnight, or Done / Skipped once its
/// window has passed.
private struct TodayRow: View {
    let schedule: ChimeSchedule
    let clock: ClockFormat
    let now: Date
    let skipToday: (Bool) -> Void

    var body: some View {
        if schedule.hasEnded(at: now, calendar: .current) {
            let skipped = schedule.isSkipped(at: now)
            LabeledContent {
                Label(skipped ? "Skipped" : "Done", systemImage: skipped ? "slash.circle" : "checkmark.circle")
            } label: {
                title
            }
            .foregroundStyle(.secondary)
        } else {
            Toggle(isOn: Binding(get: { !schedule.isSkipped(at: now) }, set: { isOn in skipToday(!isOn) })) {
                title
            }
        }
    }

    private var title: some View {
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
