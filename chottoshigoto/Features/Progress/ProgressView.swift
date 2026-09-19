import SwiftUI
import Charts

struct ProgressView: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var selectedMonth: Date = Date()
    @State private var viewMode: ViewMode = .month

    enum ViewMode: String, CaseIterable {
        case month = "Month"
        case year = "Year"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    headerSection

                    // Month / Year toggle
                    Picker("Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 4)
                    .onChange(of: viewMode) { _, newMode in
                        if newMode == .month {
                            withAnimation { selectedMonth = Date() }
                        }
                    }

                    // Content
                    switch viewMode {
                    case .month:
                        monthContent
                    case .year:
                        yearContent
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.chottoCream.ignoresSafeArea())
            .navigationTitle("Progress")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    withAnimation { changePeriod(by: -1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 2) {
                    Text(headerTitle)
                        .font(.system(size: 28, weight: .light, design: .serif))

                    if viewMode == .year && !isCurrentYear {
                        Text("\(currentYear)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    withAnimation { changePeriod(by: 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isCurrentPeriod)
                .opacity(isCurrentPeriod ? 0.3 : 1.0)
            }
            .padding(.horizontal, 4)

            Text(headerSubtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    private var headerTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .month:
            formatter.dateFormat = "MMMM"
            return formatter.string(from: selectedMonth)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: selectedMonth)
        }
    }

    private var headerSubtitle: String {
        let range = currentRange
        let sessions = sessionsInRange(range)
        let days = Set(sessions.map { Calendar.current.startOfDay(for: $0.endedAt) }).count
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        let count = sessions.count
        let time = formatTime(totalSeconds)
        return "\(days) days · \(count) Chottos · \(time)"
    }

    // MARK: - Month Content

    private var monthContent: some View {
        VStack(spacing: 28) {
            // Contribution grid
            contributionGrid

            // Practice section
            practiceSection

            // Categories
            categorySection
        }
    }

    // MARK: - Year Content

    private var yearContent: some View {
        VStack(spacing: 28) {
            // Monthly Chottos bar chart
            yearChottosChart

            // Monthly average duration
            yearDurationChart

            // Categories
            categorySection
        }
    }

    // MARK: - Contribution Grid

    private var contributionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            MonthGrid(
                month: selectedMonth,
                sessionStore: sessionStore
            )
        }
    }

    // MARK: - Practice Section (Month)

    private var practiceSection: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Practice")
                .font(.system(size: 20, weight: .light, design: .serif))

            // Chottos per week
            VStack(alignment: .leading, spacing: 8) {
                Text("Chottos / week")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                let weeklyData = weeklyChottosData
                Chart(weeklyData) { week in
                    BarMark(
                        x: .value("Week", week.label),
                        y: .value("Chottos", week.count)
                    )
                    .foregroundStyle(Color.chottoSage)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: weeklyData.map { $0.label }) { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let int = value.as(Int.self) {
                                Text("\(int)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 120)
            }

            // Average Chotto per week
            VStack(alignment: .leading, spacing: 8) {
                Text("Average Chotto")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                let weeklyData = weeklyDurationData
                Chart(weeklyData) { week in
                    LineMark(
                        x: .value("Week", week.label),
                        y: .value("Minutes", week.avgMinutes)
                    )
                    .foregroundStyle(Color.chottoSage)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Week", week.label),
                        y: .value("Minutes", week.avgMinutes)
                    )
                    .foregroundStyle(Color.chottoSage)
                    .symbolSize(40)
                }
                .chartXAxis {
                    AxisMarks(values: weeklyData.map { $0.label }) { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let double = value.as(Double.self) {
                                Text("\(Int(double))m")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 120)
            }
        }
    }

    // MARK: - Year Charts

    private var yearChottosChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chottos / month")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            let monthlyData = monthlyChottosData
            Chart(monthlyData) { month in
                BarMark(
                    x: .value("Month", month.label),
                    y: .value("Chottos", month.count)
                )
                .foregroundStyle(Color.chottoSage)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: monthlyData.map { $0.label }) { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let int = value.as(Int.self) {
                            Text("\(int)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 160)
        }
    }

    private var yearDurationChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Average Chotto")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            let monthlyData = monthlyDurationData
            Chart(monthlyData) { month in
                LineMark(
                    x: .value("Month", month.label),
                    y: .value("Minutes", month.avgMinutes)
                )
                .foregroundStyle(Color.chottoSage)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Month", month.label),
                    y: .value("Minutes", month.avgMinutes)
                )
                .foregroundStyle(Color.chottoSage)
                .symbolSize(40)
            }
            .chartXAxis {
                AxisMarks(values: monthlyData.map { $0.label }) { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let double = value.as(Double.self) {
                            Text("\(Int(double))m")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 120)
        }
    }

    // MARK: - Categories

    private var categorySection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("What you practiced")
                .font(.system(size: 20, weight: .light, design: .serif))

            let range = currentRange
            let sessions = sessionsInRange(range)
            let total = sessions.count

            if total == 0 {
                Text("No sessions yet")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                let categoryData = categoryBreakdown(sessions: sessions, total: total)

                VStack(spacing: 10) {
                    ForEach(categoryData) { cat in
                        HStack(spacing: 12) {
                            Text(cat.label)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 80, alignment: .leading)

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.chottoSage.opacity(0.8))
                                    .frame(width: geo.size.width * cat.percentage)
                            }
                            .frame(height: 16)

                            Text("\(cat.count)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)
                        }
                        .frame(height: 16)
                    }
                }
            }
        }
    }

    // MARK: - Data Helpers

    private var currentRange: (start: Date, end: Date) {
        let cal = Calendar.current
        switch viewMode {
        case .month:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: selectedMonth))!
            let end = cal.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .year:
            let start = cal.date(from: cal.dateComponents([.year], from: selectedMonth))!
            let end = cal.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        }
    }

    private func sessionsInRange(_ range: (start: Date, end: Date)) -> [SessionRecord] {
        sessionStore.history.filter {
            $0.endedAt >= range.start && $0.endedAt < range.end
        }
    }

    private var isCurrentPeriod: Bool {
        let cal = Calendar.current
        switch viewMode {
        case .month:
            return cal.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
        case .year:
            return cal.isDate(selectedMonth, equalTo: Date(), toGranularity: .year)
        }
    }

    private var isCurrentYear: Bool {
        Calendar.current.component(.year, from: selectedMonth) == Calendar.current.component(.year, from: Date())
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: selectedMonth)
    }

    private func changePeriod(by value: Int) {
        let component: Calendar.Component = viewMode == .month ? .month : .year
        if let newDate = Calendar.current.date(byAdding: component, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func formatTime(_ totalSeconds: TimeInterval) -> String {
        let hours = Int(totalSeconds / 3600)
        let mins = Int(totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60
        if hours >= 1 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    // MARK: - Weekly Data (Month)

    private struct WeekData: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let avgMinutes: Double
    }

    private var weeklyChottosData: [WeekData] {
        let cal = Calendar.current
        let range = currentRange
        let start = range.start
        let weeksInMonth = cal.range(of: .weekOfMonth, in: .month, for: selectedMonth)?.count ?? 4

        return (0..<weeksInMonth).map { week in
            let weekStart = cal.date(byAdding: .weekOfMonth, value: week, to: start)!
            let weekEnd = cal.date(byAdding: .weekOfMonth, value: 1, to: weekStart)!
            let sessions = sessionStore.history.filter {
                $0.endedAt >= weekStart && $0.endedAt < weekEnd
            }
            let day = cal.component(.day, from: weekStart)
            return WeekData(
                label: "\(day)",
                count: sessions.count,
                avgMinutes: 0
            )
        }
    }

    private var weeklyDurationData: [WeekData] {
        let cal = Calendar.current
        let range = currentRange
        let start = range.start
        let weeksInMonth = cal.range(of: .weekOfMonth, in: .month, for: selectedMonth)?.count ?? 4

        return (0..<weeksInMonth).map { week in
            let weekStart = cal.date(byAdding: .weekOfMonth, value: week, to: start)!
            let weekEnd = cal.date(byAdding: .weekOfMonth, value: 1, to: weekStart)!
            let sessions = sessionStore.history.filter {
                $0.endedAt >= weekStart && $0.endedAt < weekEnd
            }
            let totalMinutes = sessions.reduce(0) { $0 + $1.duration } / 60.0
            let avg = sessions.isEmpty ? 0 : totalMinutes / Double(sessions.count)
            let day = cal.component(.day, from: weekStart)
            return WeekData(
                label: "\(day)",
                count: sessions.count,
                avgMinutes: avg
            )
        }
    }

    // MARK: - Monthly Data (Year)

    private struct MonthData: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let avgMinutes: Double
    }

    private var monthlyChottosData: [MonthData] {
        let cal = Calendar.current
        let year = cal.component(.year, from: selectedMonth)
        let symbols = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

        return (0..<12).compactMap { monthIndex in
            guard let monthStart = cal.date(from: DateComponents(year: year, month: monthIndex + 1, day: 1)) else {
                return nil
            }
            let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
            guard monthEnd <= Date() || monthIndex + 1 == cal.component(.month, from: Date()) else {
                return nil
            }
            let sessions = sessionStore.history.filter {
                $0.endedAt >= monthStart && $0.endedAt < monthEnd
            }
            return MonthData(
                label: symbols[monthIndex],
                count: sessions.count,
                avgMinutes: 0
            )
        }
    }

    private var monthlyDurationData: [MonthData] {
        let cal = Calendar.current
        let year = cal.component(.year, from: selectedMonth)
        let symbols = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

        return (0..<12).compactMap { monthIndex in
            guard let monthStart = cal.date(from: DateComponents(year: year, month: monthIndex + 1, day: 1)) else {
                return nil
            }
            let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
            guard monthEnd <= Date() || monthIndex + 1 == cal.component(.month, from: Date()) else {
                return nil
            }
            let sessions = sessionStore.history.filter {
                $0.endedAt >= monthStart && $0.endedAt < monthEnd
            }
            let totalMinutes = sessions.reduce(0) { $0 + $1.duration } / 60.0
            let avg = sessions.isEmpty ? 0 : totalMinutes / Double(sessions.count)
            return MonthData(
                label: symbols[monthIndex],
                count: sessions.count,
                avgMinutes: avg
            )
        }
    }

    // MARK: - Category Breakdown

    private struct CategoryItem: Identifiable {
        let id: String
        let label: String
        let count: Int
        let percentage: Double
    }

    private func categoryBreakdown(sessions: [SessionRecord], total: Int) -> [CategoryItem] {
        var counts: [SessionCategory: Int] = [:]
        for session in sessions {
            counts[session.category, default: 0] += 1
        }
        return counts.map { (category, count) in
            CategoryItem(
                id: category.rawValue,
                label: category.label,
                count: count,
                percentage: Double(count) / Double(total)
            )
        }
        .sorted { $0.count > $1.count }
    }
}

// MARK: - Month Grid

private struct MonthGrid: View {
    let month: Date
    let sessionStore: SessionStore

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 16
    private let cellSpacing: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: cellSpacing) {
            HStack(spacing: cellSpacing) {
                // Day labels (all days)
                VStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { day in
                        Text(dayLabel(day))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 14, height: cellSize)
                    }
                }

                // Grid cells
                HStack(spacing: cellSpacing) {
                    ForEach(0..<totalWeeks, id: \.self) { week in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { day in
                                let date = dateFor(week: week, day: day)
                                let count = date != nil ? sessionStore.chottoCount(for: date!) : 0
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(gridColor(for: count))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
    }

    private var totalWeeks: Int {
        calendar.range(of: .weekOfMonth, in: .month, for: month)?.count ?? 5
    }

    private func dayLabel(_ day: Int) -> String {
        switch day {
        case 0: return "S"
        case 1: return "M"
        case 2: return "T"
        case 3: return "W"
        case 4: return "T"
        case 5: return "F"
        case 6: return "S"
        default: return ""
        }
    }

    private func dateFor(week: Int, day: Int) -> Date? {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return nil
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let dayOffset = (week * 7 + day) - (firstWeekday - 1)
        guard dayOffset >= 0 else { return nil }

        guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else {
            return nil
        }

        if calendar.component(.month, from: date) != calendar.component(.month, from: month) {
            return nil
        }

        return date
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
    ProgressView()
        .environment(SessionStore())
}
