// App.swift
// Screen Time Child
//
// App categorization models

import Foundation

// MARK: - App Category

enum AppCategory: String, Codable, CaseIterable {
    case educational = "educational"
    case recreational = "recreational"
    case utility = "utility"
    case uncategorized = "uncategorized"

    var displayName: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .educational:
            return "book.fill"
        case .recreational:
            return "gamecontroller.fill"
        case .utility:
            return "wrench.fill"
        case .uncategorized:
            return "app.fill"
        }
    }

    var color: String {
        switch self {
        case .educational:
            return "green"
        case .recreational:
            return "purple"
        case .utility:
            return "blue"
        case .uncategorized:
            return "gray"
        }
    }
}

// MARK: - App Model

struct App: Codable, Identifiable, Equatable {
    let id: UUID
    let familyId: UUID
    let bundleId: String
    let appName: String
    let category: AppCategory
    let isBlocked: Bool
    let timeLimit: Int?  // Minutes per day
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case bundleId = "bundle_id"
        case appName = "app_name"
        case category
        case isBlocked = "is_blocked"
        case timeLimit = "time_limit"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayName: String {
        appName.isEmpty ? bundleId : appName
    }

    var hasTimeLimit: Bool {
        timeLimit != nil && timeLimit! > 0
    }

    var timeLimitFormatted: String {
        guard let limit = timeLimit else { return "No limit" }
        return "\(limit) min/day"
    }
}
