// User.swift
// Screen Time Parent
//
// User and profile models

import Foundation

// MARK: - User Role

enum UserRole: String, Codable, CaseIterable {
    case parent
    case child

    var displayName: String {
        switch self {
        case .parent:
            return "Parent"
        case .child:
            return "Child"
        }
    }
}

// MARK: - User Profile

struct UserProfile: Codable, Identifiable, Equatable {
    let id: UUID
    let email: String
    var fullName: String?
    let role: UserRole
    var dateOfBirth: Date?
    var avatarUrl: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case dateOfBirth = "date_of_birth"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayName: String {
        fullName ?? email
    }

    var initials: String {
        if let fullName = fullName {
            let components = fullName.components(separatedBy: " ")
            let initials = components.compactMap { $0.first }.prefix(2)
            return String(initials).uppercased()
        }
        return String(email.prefix(2)).uppercased()
    }
}

// MARK: - Family Member Role

enum FamilyMemberRole: String, Codable, CaseIterable {
    case admin
    case parent
    case child

    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .parent:
            return "Parent"
        case .child:
            return "Child"
        }
    }

    var hasAdminPrivileges: Bool {
        self == .admin || self == .parent
    }
}

// MARK: - Family Member

struct FamilyMember: Codable, Identifiable, Equatable {
    let id: UUID
    let familyId: UUID
    let userId: UUID
    let role: FamilyMemberRole
    var nickname: String?
    let joinedAt: Date

    // Nested profile (from JOIN query)
    var userProfile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case userId = "user_id"
        case role
        case nickname
        case joinedAt = "joined_at"
        case userProfile = "user_profiles"
    }

    var displayName: String {
        nickname ?? userProfile?.displayName ?? "Unknown"
    }

    var isChild: Bool {
        role == .child
    }

    var isParent: Bool {
        role == .parent || role == .admin
    }
}

// MARK: - Auth Credentials

struct AuthCredentials {
    let email: String
    let password: String
    var fullName: String?
    var role: UserRole?
}

// MARK: - Auth Session

struct AuthSession {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: UserProfile
}

// MARK: - Sign Up Request

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let data: UserMetadata

    struct UserMetadata: Codable {
        let fullName: String
        let role: UserRole

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case role
        }
    }
}

// MARK: - Sign In Request

struct SignInRequest: Codable {
    let email: String
    let password: String
}
