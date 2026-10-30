import SwiftUI

/// Adds or edits one schedule: start and end times, and days. Saves only a valid schedule.
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
                    DatePicker("Start", selection: timeBinding(\.start), displayedComponents: .hourAndMinute)
                    DatePicker(selection: timeBinding(\.end), displayedComponents: .hourAndMinute) {
                        Text("End").foregroundStyle(schedule.endsAfterStart ? Color.primary : Color.red)
                    }
                } footer: {
                    if schedule.endsAfterStart {
                        Text("Chimes at the end time too.")
                    } else {
                        ValidationMessage("End time must be after the start time.")
                    }
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
                    if schedule.weekdays.isEmpty {
                        ValidationMessage("Select at least one day.")
                    } else {
                        Text(ChimeText.days(schedule.weekdays))
                    }
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
                    .disabled(!schedule.isValid)
                }
            }
        }
    }

    // MARK: Times

    /// Either time can be set freely; an end at or before the start shows an error and blocks saving.
    private func timeBinding(_ keyPath: WritableKeyPath<ChimeSchedule, TimeOfDay>) -> Binding<Date> {
        Binding(
            get: { date(for: schedule[keyPath: keyPath]) },
            set: { date in schedule[keyPath: keyPath] = TimeOfDay(of: date, calendar: .current) }
        )
    }

    /// DatePicker works in dates; a fixed day with no daylight saving change stands in for any day.
    private static let referenceDay = Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))

    private func date(for time: TimeOfDay) -> Date {
        Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: Self.referenceDay)!
    }
}

/// An inline form error under the field it's about: red, with an icon.
struct ValidationMessage: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Label(text, systemImage: "exclamationmark.circle.fill")
            .foregroundStyle(.red)
    }
}

#Preview {
    ScheduleEditor(schedule: ChimeSchedule(), isNew: true, onSave: { _ in }, onDelete: {})
}
