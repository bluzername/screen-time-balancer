// Family.swift
// Screen Time Parent
//
// Family and device models

import Foundation

// MARK: - Family

struct Family: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    let inviteCode: String
    let createdBy: UUID
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Family Overview

struct FamilyOverview: Codable, Identifiable {
    let id: UUID
    let name: String
    let inviteCode: String
    let createdAt: Date
    let childCount: Int
    let parentCount: Int
    let deviceCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case createdAt = "created_at"
        case childCount = "child_count"
        case parentCount = "parent_count"
        case deviceCount = "device_count"
    }

    var totalMembers: Int {
        childCount + parentCount
    }
}

// MARK: - Device Platform

enum DevicePlatform: String, Codable, CaseIterable {
    case ios
    case ipados
    case android

    var displayName: String {
        switch self {
        case .ios:
            return "iPhone"
        case .ipados:
            return "iPad"
        case .android:
            return "Android"
        }
    }

    var icon: String {
        switch self {
        case .ios:
            return "iphone"
        case .ipados:
            return "ipad"
        case .android:
            return "tablet"
        }
    }
}

// MARK: - Device

struct Device: Codable, Identifiable, Equatable {
    let id: UUID
    let childId: UUID
    let familyId: UUID
    var deviceName: String
    let deviceIdentifier: String
    let platform: DevicePlatform
    var osVersion: String?
    var appVersion: String?
    var lastSync: Date?
    var isActive: Bool
    let registeredAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case childId = "child_id"
        case familyId = "family_id"
        case deviceName = "device_name"
        case deviceIdentifier = "device_identifier"
        case platform
        case osVersion = "os_version"
        case appVersion = "app_version"
        case lastSync = "last_sync"
        case isActive = "is_active"
        case registeredAt = "registered_at"
    }

    var isOnline: Bool {
        guard let lastSync = lastSync else { return false }
        // Consider online if synced within last 5 minutes
        return Date().timeIntervalSince(lastSync) < 300
    }

    var lastSyncFormatted: String {
        guard let lastSync = lastSync else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }
}

// MARK: - Create Family Request

struct CreateFamilyRequest: Codable {
    let name: String
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case name
        case createdBy = "created_by"
    }
}

// MARK: - Join Family Request

struct JoinFamilyRequest: Codable {
    let familyId: UUID
    let userId: UUID
    let role: FamilyMemberRole
    var nickname: String?

    enum CodingKeys: String, CodingKey {
        case familyId = "family_id"
        case userId = "user_id"
        case role
        case nickname
    }
}

// MARK: - Family with Members

struct FamilyWithMembers: Identifiable {
    let family: Family
    var members: [FamilyMember]
    var devices: [Device]

    var id: UUID {
        family.id
    }

    var children: [FamilyMember] {
        members.filter { $0.isChild }
    }

    var parents: [FamilyMember] {
        members.filter { $0.isParent }
    }
}
