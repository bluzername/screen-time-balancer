// UsageReportsView.swift
// Screen Time Parent
//
// Usage reports and analytics UI

import SwiftUI
import Charts

struct UsageReportsView: View {
    let childId: UUID
    let childName: String
    @StateObject private var viewModel: UsageReportsViewModel

    init(childId: UUID, childName: String) {
        self.childId = childId
        self.childName = childName
        _viewModel = StateObject(wrappedValue: UsageReportsViewModel(childId: childId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        viewModel.loadData()
                    }
                } else {
                    // Summary cards
                    WeeklySummaryCard(report: viewModel.weeklyReport)

                    // Daily breakdown chart
                    DailyBreakdownChart(summaries: viewModel.dailySummaries)

                    // Category breakdown
                    CategoryBreakdownCard(report: viewModel.weeklyReport)

                    // Top apps
                    TopAppsCard(topApps: viewModel.topApps)
                }
            }
            .padding()
        }
        .navigationTitle("\(childName)'s Reports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { viewModel.selectedPeriod = .week }) {
                        Label("Last 7 Days", systemImage: "calendar")
                    }
                    Button(action: { viewModel.selectedPeriod = .month }) {
                        Label("Last 30 Days", systemImage: "calendar")
                    }
                } label: {
                    Image(systemName: "calendar")
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - Weekly Summary Card

struct WeeklySummaryCard: View {
    let report: WeeklyReport?

    var body: some View {
        if let report = report {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week Summary")
                            .font(.headline)
                        Text(report.weekFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(report.daysActive)/7")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("days active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Time stats
                HStack(spacing: 20) {
                    StatColumn(
                        title: "Total Time",
                        value: formatMinutes(report.totalMinutes),
                        icon: "clock.fill",
                        color: .blue
                    )

                    Divider()

                    StatColumn(
                        title: "Educational",
                        value: formatMinutes(report.totalEducationalMinutes),
                        icon: "book.fill",
                        color: .green
                    )

                    Divider()

                    StatColumn(
                        title: "Recreational",
                        value: formatMinutes(report.totalRecreationalMinutes),
                        icon: "gamecontroller.fill",
                        color: .purple
                    )
                }

                // Progress bar
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * report.educationalPercentage)

                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: geometry.size.width * (1 - report.educationalPercentage))
                    }
                }
                .frame(height: 8)
                .cornerRadius(4)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

struct StatColumn: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Daily Breakdown Chart

struct DailyBreakdownChart: View {
    let summaries: [DailyUsageSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Breakdown")
                .font(.headline)

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(summaries) { summary in
                        BarMark(
                            x: .value("Date", summary.date),
                            y: .value("Educational", summary.educationalMinutes)
                        )
                        .foregroundStyle(Color.green)

                        BarMark(
                            x: .value("Date", summary.date),
                            y: .value("Recreational", summary.recreationalMinutes)
                        )
                        .foregroundStyle(Color.purple)
                    }
                }
                .frame(height: 200)
            } else {
                // Fallback for iOS 15
                VStack(spacing: 8) {
                    ForEach(summaries) { summary in
                        DailyBarRow(summary: summary)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                Label("Educational", systemImage: "circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)

                Label("Recreational", systemImage: "circle.fill")
                    .foregroundColor(.purple)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DailyBarRow: View {
    let summary: DailyUsageSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatDate(summary.date))
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: calculateWidth(summary.educationalMinutes, geometry: geometry))

                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: calculateWidth(summary.recreationalMinutes, geometry: geometry))
                }
            }
            .frame(height: 20)
            .cornerRadius(4)
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func calculateWidth(_ minutes: Int, geometry: GeometryProxy) -> CGFloat {
        let maxMinutes = 240.0 // 4 hours max for scale
        let ratio = CGFloat(min(Double(minutes), maxMinutes)) / maxMinutes
        return geometry.size.width * ratio
    }
}

// MARK: - Category Breakdown Card

struct CategoryBreakdownCard: View {
    let report: WeeklyReport?

    var body: some View {
        if let report = report {
            VStack(alignment: .leading, spacing: 12) {
                Text("Time Distribution")
                    .font(.headline)

                HStack(spacing: 20) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 12)

                            Circle()
                                .trim(from: 0, to: report.educationalPercentage)
                                .stroke(Color.green, lineWidth: 12)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 4) {
                                Text("\(Int(report.educationalPercentage * 100))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Educational")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 120, height: 120)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        CategoryRow(
                            icon: "book.fill",
                            title: "Educational",
                            value: formatMinutes(report.totalEducationalMinutes),
                            percentage: report.educationalPercentage,
                            color: .green
                        )

                        CategoryRow(
                            icon: "gamecontroller.fill",
                            title: "Recreational",
                            value: formatMinutes(report.totalRecreationalMinutes),
                            percentage: 1 - report.educationalPercentage,
                            color: .purple
                        )

                        CategoryRow(
                            icon: "clock.fill",
                            title: "Daily Average",
                            value: formatMinutes(report.averageDailyMinutes),
                            percentage: nil,
                            color: .blue
                        )
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

struct CategoryRow: View {
    let icon: String
    let title: String
    let value: String
    let percentage: Double?
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let percentage = percentage {
                        Text("(\(Int(percentage * 100))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
    }
}

// MARK: - Top Apps Card

struct TopAppsCard: View {
    let topApps: [AppStatistics]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Used Apps")
                .font(.headline)

            if topApps.isEmpty {
                Text("No usage data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(topApps.prefix(5).enumerated()), id: \.element.id) { index, appStat in
                    TopAppRow(rank: index + 1, appStat: appStat)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TopAppRow: View {
    let rank: Int
    let appStat: AppStatistics

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30)

            // App info
            VStack(alignment: .leading, spacing: 4) {
                Text(appStat.app.appName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Label(appStat.app.category.displayName, systemImage: appStat.app.category.icon)
                    .font(.caption)
                    .foregroundColor(categoryColor(appStat.app.category))
            }

            Spacer()

            // Usage time
            VStack(alignment: .trailing, spacing: 4) {
                Text(appStat.totalTimeFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(appStat.sessionCount) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func categoryColor(_ category: AppCategory) -> Color {
        switch category {
        case .educational: return .green
        case .recreational: return .purple
        case .utility: return .gray
        case .uncategorized: return .orange
        }
    }
}

// MARK: - View Model

@MainActor
class UsageReportsViewModel: ObservableObject {
    @Published var weeklyReport: WeeklyReport?
    @Published var dailySummaries: [DailyUsageSummary] = []
    @Published var topApps: [AppStatistics] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPeriod: ReportPeriod = .week

    private let childId: UUID
    private let usageRepository = UsageRepository()

    enum ReportPeriod {
        case week, month
    }

    init(childId: UUID) {
        self.childId = childId
    }

    func loadData() {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                // Load daily summaries for the past 7 days
                let calendar = Calendar.current
                let today = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"

                var summaries: [DailyUsageSummary] = []

                for daysAgo in (0..<7).reversed() {
                    guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                        continue
                    }

                    let dateString = formatter.string(from: date)

                    if let summary = try await usageRepository.getDailySummary(
                        childId: childId,
                        date: dateString
                    ) {
                        summaries.append(summary)
                    }
                }

                dailySummaries = summaries

                // Calculate weekly report
                if !summaries.isEmpty {
                    weeklyReport = WeeklyReport(
                        childId: childId,
                        weekStartDate: calendar.date(byAdding: .day, value: -6, to: today) ?? today,
                        weekEndDate: today,
                        dailySummaries: summaries
                    )
                }

                // TODO: Load top apps from backend
                // For now, this would require additional API endpoint
                topApps = []

            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

struct UsageReportsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UsageReportsView(childId: UUID(), childName: "Emma")
        }
    }
}
