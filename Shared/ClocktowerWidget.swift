import SwiftUI
import WidgetKit

// Shared by the iOS widget and the watchOS complication.

struct ChimeEntry: TimelineEntry {
    let date: Date
    let isEnabled: Bool
}

struct ChimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChimeEntry {
        ChimeEntry(date: .now, isEnabled: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChimeEntry) -> Void) {
        completion(currentEntry())
    }

    // Reloaded by SettingsStore.save, so no refresh policy is needed.
    func getTimeline(in context: Context, completion: @escaping (Timeline<ChimeEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> ChimeEntry {
        ChimeEntry(date: .now, isEnabled: SettingsStore.load().isEnabled)
    }
}

struct ClocktowerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ChimeEntry

    private var icon: String { entry.isEnabled ? "bell.fill" : "bell.slash" }
    private var status: String { entry.isEnabled ? "Chimes On" : "Chimes Off" }

    var body: some View {
        #if os(iOS)
        if family == .systemSmall {
            smallView
        } else {
            Button(intent: ToggleChimesIntent(value: !entry.isEnabled)) {
                accessoryView
            }
            .buttonStyle(.plain)
        }
        #else
        accessoryView
        #endif
    }

    #if os(iOS)
    private var smallView: some View {
        VStack(alignment: .leading) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.tint)
            Spacer()
            Text("Clocktower")
                .font(.headline)
            Toggle(isOn: entry.isEnabled, intent: ToggleChimesIntent()) {
                Text(entry.isEnabled ? "On" : "Off")
                    .font(.subheadline)
            }
        }
    }
    #endif

    @ViewBuilder
    private var accessoryView: some View {
        switch family {
        case .accessoryInline:
            Label(status, systemImage: icon)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Label("Clocktower", systemImage: icon)
                    .font(.headline)
                Text(status)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        #if os(watchOS)
        case .accessoryCorner:
            Image(systemName: icon)
                .font(.title3)
                .widgetLabel(status)
        #endif
        default:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: icon)
                    .font(.title2)
            }
        }
    }
}

struct ClocktowerWidget: Widget {
    #if os(watchOS)
    private static let families: [WidgetFamily] = [.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner]
    #else
    private static let families: [WidgetFamily] = [.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline]
    #endif

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ClocktowerWidget", provider: ChimeProvider()) { entry in
            ClocktowerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Clocktower")
        .description("Shows whether chimes are on.")
        .supportedFamilies(Self.families)
    }
}
