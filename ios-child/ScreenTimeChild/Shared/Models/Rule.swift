// Rule.swift
// Screen Time Child
//
// Screen time rules model

import Foundation

// MARK: - Screen Time Rule

struct ScreenTimeRule: Codable, Identifiable, Equatable {
    let id: UUID
    let familyId: UUID
    let childId: UUID?  // nil means applies to all children
    let name: String

    let requiredEducationalMinutes: Int
    let maxRecreationalMinutes: Int?

    let startTime: String?  // HH:MM format
    let endTime: String?    // HH:MM format
    let activeDays: [Int]   // 0=Sunday, 1=Monday, etc.

    let priority: Int
    let isActive: Bool

    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case childId = "child_id"
        case name
        case requiredEducationalMinutes = "required_educational_minutes"
        case maxRecreationalMinutes = "max_recreational_minutes"
        case startTime = "start_time"
        case endTime = "end_time"
        case activeDays = "active_days"
        case priority
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    var appliesToAllChildren: Bool {
        childId == nil
    }

    var hasTimeWindow: Bool {
        startTime != nil && endTime != nil
    }

    var hasRecreationalLimit: Bool {
        maxRecreationalMinutes != nil
    }

    var timeWindowFormatted: String {
        guard let start = startTime, let end = endTime else {
            return "All day"
        }
        return "\(start) - \(end)"
    }

    var activeDaysFormatted: String {
        if activeDays.count == 7 {
            return "Every day"
        }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let active = activeDays.sorted().map { dayNames[$0] }

        if activeDays.count == 5 && activeDays.allSatisfy({ $0 >= 1 && $0 <= 5 }) {
            return "Weekdays"
        } else if activeDays.count == 2 && activeDays.contains(0) && activeDays.contains(6) {
            return "Weekends"
        }

        return active.joined(separator: ", ")
    }

    var requirementFormatted: String {
        "\(requiredEducationalMinutes) min educational"
    }

    var recreationalLimitFormatted: String {
        guard let limit = maxRecreationalMinutes else {
            return "Unlimited recreational"
        }
        return "\(limit) min recreational max"
    }

    // MARK: - Validation

    func isActiveNow() -> Bool {
        guard isActive else { return false }

        let calendar = Calendar.current
        let now = Date()

        // Check if today is an active day
        let weekday = calendar.component(.weekday, from: now) - 1  // Convert to 0-based
        guard activeDays.contains(weekday) else { return false }

        // Check time window if specified
        if let start = startTime, let end = endTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"

            let nowTime = formatter.string(from: now)
            return nowTime >= start && nowTime <= end
        }

        return true
    }
}
