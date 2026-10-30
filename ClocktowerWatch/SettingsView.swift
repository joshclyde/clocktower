import SwiftUI

struct SettingsView: View {
    @Environment(WatchController.self) private var controller

    private var settings: ChimeSettings { controller.settings }

    var body: some View {
        NavigationStack {
            // Every minute, so today's schedules notice when a window has passed.
            TimelineView(.everyMinute) { context in
                list(now: context.date)
            }
            .navigationTitle("Clocktower")
        }
    }

    private func list(now: Date) -> some View {
        List {
            onOffSection(now: now)

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
                HStack {
                    ForEach(ClockFormat.allCases) { clock in
                        ChoiceButton(title: clock.shortLabel, isSelected: settings.clock == clock) {
                            controller.update { $0.clock = clock }
                        }
                    }
                }
                .listRowBackground(Color.clear)
                VStack {
                    ForEach(MessageStyle.allCases) { style in
                        ChoiceButton(title: ChimeText.sample(style: style, clock: settings.clock), isSelected: settings.style == style) {
                            controller.update { $0.style = style }
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }

            Section {
                Toggle("Time Sensitive", isOn: controller.binding(\.isTimeSensitive))
            } header: {
                Text("Focus")
            } footer: {
                Text("Chimes come through even when a Focus is on.")
            }
        }
    }

    /// The top section: Off / On / Schedule and, while set to Schedule, today's schedules, Snooze
    /// Today, and each schedule's toggle. Adding and editing schedules is on the iPhone.
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
        if isScheduled {
            footer += "\n\nAdd and edit schedules on your iPhone."
        }
        return Section {
            HStack {
                ForEach(ChimeMode.allCases) { mode in
                    ChoiceButton(title: mode.label, isSelected: settings.mode == mode, color: mode.color) {
                        controller.update { $0.mode = mode }
                    }
                }
            }
            .listRowBackground(Color.clear)
            if isScheduled {
                ForEach(today) { schedule in
                    let hasEnded = schedule.hasEnded(at: now, calendar: .current)
                    VStack(alignment: .leading) {
                        Text(ChimeText.window(of: schedule, clock: settings.clock))
                        Text(isSnoozed ? "Today · Snoozed" : hasEnded ? "Today · Done" : "Today")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(isSnoozed || hasEnded ? HierarchicalShapeStyle.secondary : .primary)
                }
                if showsSnooze {
                    Toggle("Snooze Today", isOn: Binding(
                        get: { isSnoozed },
                        set: { snooze in controller.update { $0.snoozeToday(snooze, at: .now, calendar: .current) } }
                    ))
                }
                ForEach(settings.schedules) { schedule in
                    Toggle(isOn: Binding(
                        get: { schedule.isEnabled },
                        set: { isOn in controller.update { settings in settings.updateSchedule(schedule.id) { $0.isEnabled = isOn } } }
                    )) {
                        VStack(alignment: .leading) {
                            Text(ChimeText.window(of: schedule, clock: settings.clock))
                            Text(ChimeText.days(schedule.weekdays))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Chimes")
        } footer: {
            Text(footer)
        }
    }
}

#Preview {
    SettingsView()
        .environment(WatchController())
}
