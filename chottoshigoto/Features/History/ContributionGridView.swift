import SwiftUI

struct ContributionGridView: View {
    @Environment(SessionStore.self) private var sessionStore

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                ForEach(0..<totalWeeks, id: \.self) { week in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { day in
                            let date = dateFor(week: week, day: day)
                            let count = date != nil ? sessionStore.chottoCount(for: date!) : 0
                            let color = gridColor(for: count)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private var totalWeeks: Int {
        let today = Date()
        guard let yearStart = calendar.date(from: DateComponents(year: calendar.component(.year, from: today), month: 1, day: 1)) else {
            return 53
        }
        let daysSinceStart = calendar.dateComponents([.day], from: yearStart, to: today).day ?? 0
        return min(53, (daysSinceStart / 7) + 2)
    }

    private func dateFor(week: Int, day: Int) -> Date? {
        let today = Date()
        guard let yearStart = calendar.date(from: DateComponents(year: calendar.component(.year, from: today), month: 1, day: 1)) else {
            return nil
        }

        let weekdayOfJan1 = calendar.component(.weekday, from: yearStart)
        let offset = weekdayOfJan1 - 2
        let dayOfYear = week * 7 + day - offset

        guard dayOfYear >= 0 else { return nil }

        guard let date = calendar.date(byAdding: .day, value: dayOfYear, to: yearStart) else {
            return nil
        }

        return date > today ? nil : date
    }

    private func gridColor(for count: Int) -> Color {
        switch count {
        case 0:     return .chottoGridEmpty
        case 1:     return .chottoGridLevel1
        case 2...3: return .chottoGridLevel2
        case 4...5: return .chottoGridLevel3
        default:    return .chottoGridLevel4
        }
    }
}

#Preview {
    ContributionGridView()
        .environment(SessionStore())
        .padding()
}
