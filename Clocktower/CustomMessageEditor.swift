import SwiftUI

/// Writes the custom message: text before the time, after it, or both, with an example of the
/// result. Saves only when at least one has text.
struct CustomMessageEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message: CustomMessage
    private let clock: ClockFormat
    private let onSave: (CustomMessage) -> Void

    init(message: CustomMessage, clock: ClockFormat, onSave: @escaping (CustomMessage) -> Void) {
        _message = State(initialValue: message)
        self.clock = clock
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Before") {
                        TextField("Before", text: $message.prefix, prompt: Text("e.g. Stand up"))
                    }
                    LabeledContent("After") {
                        TextField("After", text: $message.suffix, prompt: Text("e.g. and stretch"))
                    }
                } header: {
                    Text("Text around the time")
                } footer: {
                    Text("Fill in one or both.")
                }

                Section("Example") {
                    Text(ChimeText.message(hour: 13, minute: 20, style: .custom, clock: clock, customMessage: message))
                        .foregroundStyle(message.isValid ? Color.primary : Color.secondary)
                }
            }
            .navigationTitle("Custom Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(message)
                        dismiss()
                    }
                    .disabled(!message.isValid)
                }
            }
        }
    }
}

#Preview {
    CustomMessageEditor(message: CustomMessage(), clock: .twelveHour, onSave: { _ in })
}
