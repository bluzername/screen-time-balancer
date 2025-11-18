// Rule.swift
// Screen Time Parent
//
// Screen time rules models

import Foundation

// MARK: - Screen Time Rule

struct ScreenTimeRule: Codable, Identifiable, Equatable {
    let id: UUID
    let familyId: UUID
    let childId: UUID?  // nil = applies to all children
    var name: String
    var description: String?

    // Educational requirements
    var requiredEducationalMinutes: Int

    // Recreational limits
    var maxRecreationalMinutes: Int?

    // Time windows
    var startTime: String?  // "HH:mm:ss" format
    var endTime: String?

    // Active days (0=Sunday, 6=Saturday)
    var activeDays: [Int]

    // Priority (higher = more important)
    var priority: Int

    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case childId = "child_id"
        case name
        case description
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

    var appliesToAllChildren: Bool {
        childId == nil
    }

    var educationalTimeFormatted: String {
        formatMinutes(requiredEducationalMinutes)
    }

    var recreationalTimeFormatted: String? {
        guard let max = maxRecreationalMinutes else { return nil }
        return formatMinutes(max)
    }

    var timeWindowFormatted: String {
        if let start = startTime, let end = endTime {
            return "\(formatTime(start)) - \(formatTime(end))"
        }
        return "All day"
    }

    var activeDaysFormatted: String {
        if activeDays.count == 7 {
            return "Every day"
        }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let selectedDays = activeDays.sorted().map { dayNames[$0] }

        if selectedDays.count <= 3 {
            return selectedDays.joined(separator: ", ")
        } else {
            return "\(selectedDays.count) days"
        }
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
            return "\(minutes) min"
        }
    }

    private func formatTime(_ time: String) -> String {
        // Convert "HH:mm:ss" to "h:mm a"
        let components = time.components(separatedBy: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return time
        }

        let isPM = hour >= 12
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let period = isPM ? "PM" : "AM"

        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    func isActiveOn(dayOfWeek: Int) -> Bool {
        activeDays.contains(dayOfWeek)
    }

    func isActiveNow() -> Bool {
        guard isActive else { return false }

        let now = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: now) - 1 // Convert to 0-based

        guard isActiveOn(dayOfWeek: dayOfWeek) else { return false }

        // Check time window if specified
        if let start = startTime, let end = endTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"

            guard let startDate = formatter.date(from: start),
                  let endDate = formatter.date(from: end) else {
                return true
            }

            let nowComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
            let currentTime = calendar.date(from: nowComponents) ?? now

            let startComponents = calendar.dateComponents([.hour, .minute, .second], from: startDate)
            let endComponents = calendar.dateComponents([.hour, .minute, .second], from: endDate)

            guard let start = calendar.date(from: startComponents),
                  let end = calendar.date(from: endComponents) else {
                return true
            }

            return currentTime >= start && currentTime <= end
        }

        return true
    }
}

// MARK: - Create Rule Request

struct CreateRuleRequest: Codable {
    let familyId: UUID
    let childId: UUID?
    let name: String
    var description: String?
    let requiredEducationalMinutes: Int
    var maxRecreationalMinutes: Int?
    var startTime: String?
    var endTime: String?
    var activeDays: [Int]
    var priority: Int
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case familyId = "family_id"
        case childId = "child_id"
        case name
        case description
        case requiredEducationalMinutes = "required_educational_minutes"
        case maxRecreationalMinutes = "max_recreational_minutes"
        case startTime = "start_time"
        case endTime = "end_time"
        case activeDays = "active_days"
        case priority
        case isActive = "is_active"
    }
}

// MARK: - Update Rule Request

struct UpdateRuleRequest: Codable {
    var name: String?
    var description: String?
    var requiredEducationalMinutes: Int?
    var maxRecreationalMinutes: Int?
    var startTime: String?
    var endTime: String?
    var activeDays: [Int]?
    var priority: Int?
    var isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case requiredEducationalMinutes = "required_educational_minutes"
        case maxRecreationalMinutes = "max_recreational_minutes"
        case startTime = "start_time"
        case endTime = "end_time"
        case activeDays = "active_days"
        case priority
        case isActive = "is_active"
    }
}

// MARK: - Rule Template

struct RuleTemplate {
    let name: String
    let description: String
    let requiredEducationalMinutes: Int
    let maxRecreationalMinutes: Int
    let startTime: String?
    let endTime: String?
    let activeDays: [Int]

    static let weekdaySchool = RuleTemplate(
        name: "School Days",
        description: "Balanced screen time for school days",
        requiredEducationalMinutes: 30,
        maxRecreationalMinutes: 60,
        startTime: "15:00:00",  // 3 PM
        endTime: "20:00:00",    // 8 PM
        activeDays: [1, 2, 3, 4, 5]  // Mon-Fri
    )

    static let weekend = RuleTemplate(
        name: "Weekends",
        description: "More flexible time on weekends",
        requiredEducationalMinutes: 20,
        maxRecreationalMinutes: 120,
        startTime: "08:00:00",
        endTime: "21:00:00",
        activeDays: [0, 6]  // Sat-Sun
    )

    static let balanced = RuleTemplate(
        name: "Balanced",
        description: "Equal educational and recreational time",
        requiredEducationalMinutes: 30,
        maxRecreationalMinutes: 90,
        startTime: nil,
        endTime: nil,
        activeDays: [0, 1, 2, 3, 4, 5, 6]  // All days
    )

    static let strict = RuleTemplate(
        name: "Strict",
        description: "Higher educational requirements",
        requiredEducationalMinutes: 60,
        maxRecreationalMinutes: 60,
        startTime: nil,
        endTime: nil,
        activeDays: [0, 1, 2, 3, 4, 5, 6]
    )

    static let templates: [RuleTemplate] = [
        .balanced,
        .weekdaySchool,
        .weekend,
        .strict
    ]
}
