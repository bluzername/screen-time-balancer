// Usage.swift
// Screen Time Parent
//
// Usage tracking and earned time models

import Foundation

// MARK: - Usage Session

struct UsageSession: Codable, Identifiable, Equatable {
    let id: UUID
    let childId: UUID
    let deviceId: UUID
    let appId: UUID?
    let bundleId: String
    let appName: String
    let category: AppCategory

    let startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int?

    let date: String  // YYYY-MM-DD format
    let syncedAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case childId = "child_id"
        case deviceId = "device_id"
        case appId = "app_id"
        case bundleId = "bundle_id"
        case appName = "app_name"
        case category
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSeconds = "duration_seconds"
        case date
        case syncedAt = "synced_at"
        case createdAt = "created_at"
    }

    var isActive: Bool {
        endedAt == nil
    }

    var durationMinutes: Int {
        guard let seconds = durationSeconds else { return 0 }
        return seconds / 60
    }

    var durationFormatted: String {
        guard let seconds = durationSeconds else { return "Active" }

        let minutes = seconds / 60
        let remainingSeconds = seconds % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        } else if minutes > 0 {
            if remainingSeconds > 0 {
                return "\(minutes)m \(remainingSeconds)s"
            } else {
                return "\(minutes)m"
            }
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Earned Time

struct EarnedTime: Codable, Identifiable, Equatable {
    let id: UUID
    let childId: UUID
    let familyId: UUID
    let date: String  // YYYY-MM-DD format

    var educationalMinutes: Int
    let requiredEducationalMinutes: Int
    var recreationalMinutesUsed: Int
    var recreationalMinutesAvailable: Int

    var requirementMet: Bool
    let lastCalculated: Date

    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case childId = "child_id"
        case familyId = "family_id"
        case date
        case educationalMinutes = "educational_minutes"
        case requiredEducationalMinutes = "required_educational_minutes"
        case recreationalMinutesUsed = "recreational_minutes_used"
        case recreationalMinutesAvailable = "recreational_minutes_available"
        case requirementMet = "requirement_met"
        case lastCalculated = "last_calculated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var progressPercentage: Double {
        guard requiredEducationalMinutes > 0 else { return 1.0 }
        return min(Double(educationalMinutes) / Double(requiredEducationalMinutes), 1.0)
    }

    var remainingEducationalMinutes: Int {
        max(requiredEducationalMinutes - educationalMinutes, 0)
    }

    var remainingRecreationalMinutes: Int {
        max(recreationalMinutesAvailable - recreationalMinutesUsed, 0)
    }

    var educationalTimeFormatted: String {
        "\(educationalMinutes) / \(requiredEducationalMinutes) min"
    }

    var recreationalTimeFormatted: String {
        "\(recreationalMinutesUsed) / \(recreationalMinutesAvailable) min"
    }
}

// MARK: - Daily Usage Summary

struct DailyUsageSummary: Codable, Identifiable {
    let childId: UUID
    let date: String
    let deviceId: UUID?

    let educationalMinutes: Int
    let recreationalMinutes: Int
    let totalMinutes: Int
    let uniqueAppsUsed: Int

    let firstUsage: Date?
    let lastUsage: Date?

    enum CodingKeys: String, CodingKey {
        case childId = "child_id"
        case date
        case deviceId = "device_id"
        case educationalMinutes = "educational_minutes"
        case recreationalMinutes = "recreational_minutes"
        case totalMinutes = "total_minutes"
        case uniqueAppsUsed = "unique_apps_used"
        case firstUsage = "first_usage"
        case lastUsage = "last_usage"
    }

    var id: String {
        "\(childId.uuidString)-\(date)"
    }

    var educationalPercentage: Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(educationalMinutes) / Double(totalMinutes)
    }

    var recreationalPercentage: Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(recreationalMinutes) / Double(totalMinutes)
    }

    var totalTimeFormatted: String {
        formatMinutes(totalMinutes)
    }

    var educationalTimeFormatted: String {
        formatMinutes(educationalMinutes)
    }

    var recreationalTimeFormatted: String {
        formatMinutes(recreationalMinutes)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Current Enforcement Status

struct EnforcementStatus: Codable, Identifiable {
    let childId: UUID
    let date: String

    let educationalMinutes: Int
    let requiredEducationalMinutes: Int
    let recreationalMinutesAvailable: Int
    let recreationalMinutesUsed: Int
    let requirementMet: Bool

    let childName: String?
    let deviceName: String?
    let lastSync: Date?

    enum CodingKeys: String, CodingKey {
        case childId = "child_id"
        case date
        case educationalMinutes = "educational_minutes"
        case requiredEducationalMinutes = "required_educational_minutes"
        case recreationalMinutesAvailable = "recreational_minutes_available"
        case recreationalMinutesUsed = "recreational_minutes_used"
        case requirementMet = "requirement_met"
        case childName = "child_name"
        case deviceName = "device_name"
        case lastSync = "last_sync"
    }

    var id: UUID {
        childId
    }

    var isLocked: Bool {
        !requirementMet
    }

    var progressPercentage: Double {
        guard requiredEducationalMinutes > 0 else { return 1.0 }
        return min(Double(educationalMinutes) / Double(requiredEducationalMinutes), 1.0)
    }
}

// MARK: - Weekly Report

struct WeeklyReport: Identifiable {
    let childId: UUID
    let weekStartDate: Date
    let weekEndDate: Date

    var dailySummaries: [DailyUsageSummary]

    var id: String {
        "\(childId.uuidString)-\(weekStartDate.timeIntervalSince1970)"
    }

    var totalEducationalMinutes: Int {
        dailySummaries.reduce(0) { $0 + $1.educationalMinutes }
    }

    var totalRecreationalMinutes: Int {
        dailySummaries.reduce(0) { $0 + $1.recreationalMinutes }
    }

    var totalMinutes: Int {
        dailySummaries.reduce(0) { $0 + $1.totalMinutes }
    }

    var averageDailyMinutes: Int {
        guard !dailySummaries.isEmpty else { return 0 }
        return totalMinutes / dailySummaries.count
    }

    var daysActive: Int {
        dailySummaries.filter { $0.totalMinutes > 0 }.count
    }

    var topApps: [AppStatistics] {
        // Would be calculated from usage sessions
        []
    }

    var educationalPercentage: Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(totalEducationalMinutes) / Double(totalMinutes)
    }

    var weekFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short

        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }
}

// MARK: - Create Usage Session Request

struct CreateUsageSessionRequest: Codable {
    let childId: UUID
    let deviceId: UUID
    let bundleId: String
    let appName: String
    let category: AppCategory
    let startedAt: Date
    let date: String

    enum CodingKeys: String, CodingKey {
        case childId = "child_id"
        case deviceId = "device_id"
        case bundleId = "bundle_id"
        case appName = "app_name"
        case category
        case startedAt = "started_at"
        case date
    }
}
