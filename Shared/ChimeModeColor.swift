import SwiftUI

extension ChimeMode {
    /// Fill for the selected Off / On / Schedule button.
    var color: Color {
        switch self {
        case .off: return .red
        case .on: return .green
        case .schedule: return .blue
        }
    }
}
