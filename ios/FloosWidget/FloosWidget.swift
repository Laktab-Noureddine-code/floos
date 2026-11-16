import SwiftUI
import WidgetKit

// iOS WidgetKit source for Floos. Add a "Widget Extension" target named
// FloosWidget in Xcode, enable the App Group `group.com.floos.app` on both
// the Runner and the extension, and include this file in the extension.

struct FloosEntry: TimelineEntry {
    let date: Date
    let spent: String
    let income: String
    let balance: String
    let labelSpent: String
    let labelIncome: String
    let labelBalance: String
}

struct FloosProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.com.floos.app")

    private func entry() -> FloosEntry {
        FloosEntry(
            date: Date(),
            spent: defaults?.string(forKey: "spent_month") ?? "—",
            income: defaults?.string(forKey: "income_month") ?? "—",
            balance: defaults?.string(forKey: "balance") ?? "—",
            labelSpent: defaults?.string(forKey: "label_spent") ?? "",
            labelIncome: defaults?.string(forKey: "label_income") ?? "",
            labelBalance: defaults?.string(forKey: "label_balance") ?? ""
        )
    }

    func placeholder(in context: Context) -> FloosEntry { entry() }
    func getSnapshot(in context: Context, completion: @escaping (FloosEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FloosEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .never))
    }
}

struct FloosWidgetView: View {
    let entry: FloosEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.labelSpent).font(.caption).foregroundColor(.secondary)
            Text(entry.spent).font(.title2).bold()
            Text(entry.labelIncome).font(.caption).foregroundColor(.secondary)
            Text(entry.income).font(.headline).foregroundColor(.green)
            Text(entry.labelBalance).font(.caption).foregroundColor(.secondary)
            Text(entry.balance).font(.headline)
        }
        .padding()
        .widgetURL(URL(string: "floos://add"))
    }
}

@main
struct FloosWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FloosWidget", provider: FloosProvider()) { entry in
            FloosWidgetView(entry: entry)
        }
        .configurationDisplayName("Floos")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
