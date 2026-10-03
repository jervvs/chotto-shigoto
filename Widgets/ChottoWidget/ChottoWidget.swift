import Foundation
import WidgetKit
import SwiftUI

struct ChottoTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChottoEntry {
        ChottoEntry(date: Date(), state: .idle)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChottoEntry) -> Void) {
        completion(ChottoEntry(date: Date(), state: .idle))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChottoEntry>) -> Void) {
        let entry = ChottoEntry(date: Date(), state: .idle)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct ChottoEntry: TimelineEntry {
    let date: Date
    let state: WidgetState
}

enum WidgetState {
    case idle
    case active(remaining: String)
    case completed
}

struct ChottoWidgetEntryView: View {
    var entry: ChottoTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch entry.state {
        case .idle:
            idleView
        case .active(let remaining):
            activeView(remaining: remaining)
        case .completed:
            completedView
        }
    }

    private var idleView: some View {
        VStack(spacing: 6) {
            Text("chotto shigoto")
                .font(.system(size: 18, weight: .light, design: .serif))
            Text("Set timer in app")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
            Button(intent: WidgetStartChottoIntent()) {
                Text("Start")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private func activeView(remaining: String) -> some View {
        VStack(spacing: 4) {
            Text(remaining)
                .font(.system(size: 32, weight: .thin, design: .monospaced))
            Text("仕事中")
                .font(.system(size: 12, weight: .light, design: .serif))
                .foregroundStyle(.secondary)
        }
    }

    private var completedView: some View {
        VStack(spacing: 4) {
            Text("お疲れ様でした。")
                .font(.system(size: 14, weight: .light, design: .serif))
            Button(intent: WidgetStartChottoIntent()) {
                Text("mou chotto")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

struct ChottoWidget: Widget {
    let kind: String = "ChottoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChottoTimelineProvider()) { entry in
            ChottoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Chotto")
        .description("Quick start a focus session")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ChottoWidget()
} timeline: {
    ChottoEntry(date: Date(), state: .idle)
    ChottoEntry(date: Date(), state: .active(remaining: "24:37"))
    ChottoEntry(date: Date(), state: .completed)
}
