import SwiftUI

/// Adds or edits one schedule: start time, optional end time, and days.
struct ScheduleEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var schedule: ChimeSchedule
    private let isNew: Bool
    private let onSave: (ChimeSchedule) -> Void
    private let onDelete: () -> Void

    init(schedule: ChimeSchedule, isNew: Bool, onSave: @escaping (ChimeSchedule) -> Void, onDelete: @escaping () -> Void) {
        _schedule = State(initialValue: schedule)
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start", selection: startBinding, displayedComponents: .hourAndMinute)
                    Toggle("End Time", isOn: hasEndBinding)
                        .disabled(schedule.start == .lastMinute)
                    if schedule.end != nil {
                        DatePicker("End", selection: endBinding, in: endRange, displayedComponents: .hourAndMinute)
                    }
                } footer: {
                    Text(schedule.end == nil ? "Chimes until midnight." : "Chimes at the end time too.")
                }

                Section {
                    HStack {
                        ForEach(Weekday.allCases) { day in
                            ChoiceButton(title: day.letter, isSelected: schedule.weekdays.contains(day)) {
                                if schedule.weekdays.contains(day) {
                                    schedule.weekdays.remove(day)
                                } else {
                                    schedule.weekdays.insert(day)
                                }
                            }
                            .accessibilityLabel(day.shortLabel)
                        }
                    }
                } header: {
                    Text("Days")
                } footer: {
                    Text(schedule.weekdays.isEmpty ? "No days selected: every day." : ChimeText.days(schedule.weekdays))
                }

                if !isNew {
                    Section {
                        Button("Delete Schedule", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Add" : "Save") {
                        onSave(schedule)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: Times

    /// Moving the start to or past the end pushes the end an hour after it (or clears it at 11:59 PM),
    /// so the end always stays after the start.
    private var startBinding: Binding<Date> {
        Binding(
            get: { date(for: schedule.start) },
            set: { date in
                let start = TimeOfDay(of: date, calendar: .current)
                schedule.start = start
                if let end = schedule.end, end <= start {
                    schedule.end = defaultEnd(after: start)
                }
            }
        )
    }

    private var hasEndBinding: Binding<Bool> {
        Binding(
            get: { schedule.end != nil },
            set: { hasEnd in schedule.end = hasEnd ? defaultEnd(after: schedule.start) : nil }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { date(for: schedule.end ?? .lastMinute) },
            set: { date in schedule.end = TimeOfDay(of: date, calendar: .current) }
        )
    }

    /// Only times after the start.
    private var endRange: ClosedRange<Date> {
        let earliest = TimeOfDay(minuteOfDay: min(schedule.start.minuteOfDay + 1, TimeOfDay.lastMinute.minuteOfDay))
        return date(for: earliest)...date(for: .lastMinute)
    }

    private func defaultEnd(after start: TimeOfDay) -> TimeOfDay? {
        guard start < .lastMinute else { return nil }
        return TimeOfDay(minuteOfDay: min(start.minuteOfDay + 60, TimeOfDay.lastMinute.minuteOfDay))
    }

    /// DatePicker works in dates; a fixed day with no daylight saving change stands in for any day.
    private static let referenceDay = Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))

    private func date(for time: TimeOfDay) -> Date {
        Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: Self.referenceDay)!
    }
}

#Preview {
    ScheduleEditor(schedule: ChimeSchedule(), isNew: true, onSave: { _ in }, onDelete: {})
}
