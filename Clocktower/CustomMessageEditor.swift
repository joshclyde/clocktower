import SwiftUI

/// Writes the custom message: text before the time, after it, both, or neither, with an example
/// of the result.
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
                    Text("Both are optional. Leave them empty to show just the time.")
                }

                Section("Example") {
                    Text(ChimeText.sample(clock: clock, customMessage: message))
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
                }
            }
        }
    }
}

#Preview {
    CustomMessageEditor(message: CustomMessage(), clock: .twelveHour, onSave: { _ in })
}
