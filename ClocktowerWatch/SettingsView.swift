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

            schedulesSection
        }
    }

    /// The on/off controls, together at the top: the master toggle, Infinite, and today's schedules
    /// (shown while chimes are on; dimmed while Infinite is on).
    private func onOffSection(now: Date) -> some View {
        let today = settings.isEnabled ? settings.todaysSchedules(at: now, calendar: .current) : []
        var footer = ChimeText.appDescription(for: settings)
        if !today.isEmpty {
            footer += settings.isInfinite ? "\n\nInfinite is on, so today's schedules aren't used." : "\n\nTurning one off lasts until midnight."
        }
        return Section {
            Toggle(isOn: controller.binding(\.isEnabled)) {
                Label("Chimes", systemImage: settings.isEnabled ? "bell.fill" : "bell.slash")
            }
            Toggle("Infinite", isOn: controller.binding(\.isInfinite))
            ForEach(today) { schedule in
                let window = ChimeText.window(of: schedule, clock: settings.clock)
                Group {
                    if schedule.hasEnded(at: now, calendar: .current) {
                        VStack(alignment: .leading) {
                            Text(window)
                            Text(schedule.isSkipped(at: now) ? "Today · Skipped" : "Today · Done")
                                .font(.footnote)
                        }
                        .foregroundStyle(.secondary)
                    } else {
                        Toggle(isOn: Binding(
                            get: { !schedule.isSkipped(at: now) },
                            set: { isOn in
                                controller.update { settings in
                                    settings.updateSchedule(schedule.id) { $0.skipToday(!isOn, at: .now, calendar: .current) }
                                }
                            }
                        )) {
                            VStack(alignment: .leading) {
                                Text(window)
                                Text("Today")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .disabled(settings.isInfinite)
            }
        } footer: {
            Text(footer)
        }
    }

    /// Each schedule can be turned on and off here; adding and editing them is on the iPhone.
    private var schedulesSection: some View {
        Section {
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
        } header: {
            Text("Schedules")
        } footer: {
            Text(settings.isInfinite
                ? "Infinite is on, so schedules aren't used. Add and edit schedules on your iPhone."
                : "Add and edit schedules on your iPhone.")
        }
    }
}

#Preview {
    SettingsView()
        .environment(WatchController())
}
