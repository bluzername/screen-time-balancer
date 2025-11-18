// App.swift
// Screen Time Parent
//
// App categorization models

import Foundation

// MARK: - App Category

enum AppCategory: String, Codable, CaseIterable {
    case educational
    case recreational
    case utility
    case uncategorized

    var displayName: String {
        switch self {
        case .educational:
            return "Educational"
        case .recreational:
            return "Recreational"
        case .utility:
            return "Utility"
        case .uncategorized:
            return "Uncategorized"
        }
    }

    var icon: String {
        switch self {
        case .educational:
            return "book.fill"
        case .recreational:
            return "gamecontroller.fill"
        case .utility:
            return "wrench.and.screwdriver.fill"
        case .uncategorized:
            return "app.fill"
        }
    }

    var color: String {
        switch self {
        case .educational:
            return "green"
        case .recreational:
            return "blue"
        case .utility:
            return "gray"
        case .uncategorized:
            return "orange"
        }
    }

    var description: String {
        switch self {
        case .educational:
            return "Apps that help learning and education"
        case .recreational:
            return "Games, social media, and entertainment"
        case .utility:
            return "Tools and essential apps"
        case .uncategorized:
            return "Not yet categorized"
        }
    }
}

// MARK: - App

struct App: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let familyId: UUID
    let bundleId: String
    var appName: String
    var category: AppCategory
    var iconUrl: String?
    var isBlocked: Bool
    var timeLimitMinutes: Int?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case bundleId = "bundle_id"
        case appName = "app_name"
        case category
        case iconUrl = "icon_url"
        case isBlocked = "is_blocked"
        case timeLimitMinutes = "time_limit_minutes"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var hasTimeLimit: Bool {
        timeLimitMinutes != nil && timeLimitMinutes! > 0
    }

    var timeLimitFormatted: String? {
        guard let limit = timeLimitMinutes else { return nil }
        if limit >= 60 {
            let hours = limit / 60
            let minutes = limit % 60
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(minutes)m"
            }
        } else {
            return "\(limit)m"
        }
    }
}

// MARK: - Create App Request

struct CreateAppRequest: Codable {
    let familyId: UUID
    let bundleId: String
    let appName: String
    let category: AppCategory
    var iconUrl: String?
    var isBlocked: Bool
    var timeLimitMinutes: Int?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case familyId = "family_id"
        case bundleId = "bundle_id"
        case appName = "app_name"
        case category
        case iconUrl = "icon_url"
        case isBlocked = "is_blocked"
        case timeLimitMinutes = "time_limit_minutes"
        case notes
    }
}

// MARK: - Update App Request

struct UpdateAppRequest: Codable {
    var category: AppCategory?
    var isBlocked: Bool?
    var timeLimitMinutes: Int?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case category
        case isBlocked = "is_blocked"
        case timeLimitMinutes = "time_limit_minutes"
        case notes
    }
}

// MARK: - Installed App (from device)

struct InstalledApp: Identifiable, Equatable, Hashable {
    let id = UUID()
    let bundleId: String
    let name: String
    var iconData: Data?

    // Categorization status
    var category: AppCategory = .uncategorized
    var isCategorized: Bool {
        category != .uncategorized
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleId)
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.bundleId == rhs.bundleId
    }
}

// MARK: - App Statistics

struct AppStatistics: Identifiable {
    let app: App
    var totalMinutes: Int
    var sessionCount: Int
    var lastUsed: Date?

    var id: UUID {
        app.id
    }

    var totalTimeFormatted: String {
        formatMinutes(totalMinutes)
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
