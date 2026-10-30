import SwiftUI

/// A selectable button used for the Chimes, interval and clock options in both apps.
struct ChoiceButton: View {
    let title: String
    let isSelected: Bool
    /// The fill while selected.
    var color: Color = .accentColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? color : Color.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        // Plain style keeps several buttons in one List row independently tappable.
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
