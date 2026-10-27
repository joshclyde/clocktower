import SwiftUI
import WidgetKit

// Shared by the iOS widget and the watchOS complication.

struct ClocktowerEntry: TimelineEntry {
    let date: Date
}

struct ClocktowerProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClocktowerEntry {
        ClocktowerEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClocktowerEntry) -> Void) {
        completion(ClocktowerEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClocktowerEntry>) -> Void) {
        completion(Timeline(entries: [ClocktowerEntry(date: .now)], policy: .never))
    }
}

struct ClocktowerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClocktowerEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Label("Clocktower", systemImage: "bell")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "bell.fill")
                    .font(.title2)
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text("Clocktower")
                    .font(.headline)
                Text("No chimes set")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        #if os(watchOS)
        case .accessoryCorner:
            Image(systemName: "bell.fill")
                .font(.title3)
        #endif
        default:
            VStack(spacing: 8) {
                Image(systemName: "bell.badge")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                Text("Clocktower")
                    .font(.headline)
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
        StaticConfiguration(kind: "ClocktowerWidget", provider: ClocktowerProvider()) { entry in
            ClocktowerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Clocktower")
        .description("Your next chime.")
        .supportedFamilies(Self.families)
    }
}
