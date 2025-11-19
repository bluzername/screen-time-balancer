// FamilyRepository.swift
// Screen Time Child
//
// Family operations for child app

import Foundation
import Supabase

protocol FamilyRepositoryProtocol {
    func getFamilyByInviteCode(_ code: String) async throws -> Family
    func joinFamily(inviteCode: String, userId: UUID, role: FamilyMemberRole) async throws -> JoinFamilyResult
}

class FamilyRepository: FamilyRepositoryProtocol {
    private let client = SupabaseClientManager.shared.client

    func getFamilyByInviteCode(_ code: String) async throws -> Family {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.getFamilyByInviteCode") {
            try await self.client.database
                .from("families")
                .select()
                .eq("invite_code", value: code.uppercased())
                .single()
                .execute()
                .value
        }
    }

    func joinFamily(inviteCode: String, userId: UUID, role: FamilyMemberRole) async throws -> JoinFamilyResult {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.joinFamily") {
            // First, get the family
            let family = try await self.getFamilyByInviteCode(inviteCode)

            // Create family member request
            let memberRequest = JoinFamilyRequest(
                familyId: family.id,
                userId: userId,
                role: role,
                nickname: nil
            )

            // Add user to family
            let member: FamilyMember = try await self.client.database
                .from("family_members")
                .insert(memberRequest)
                .select()
                .single()
                .execute()
                .value

            return JoinFamilyResult(family: family, member: member)
        }
    }
}

// MARK: - Models

struct Family: Codable, Identifiable {
    let id: UUID
    let name: String
    let inviteCode: String
    let createdBy: UUID
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct FamilyMember: Codable, Identifiable {
    let id: UUID
    let familyId: UUID
    let userId: UUID
    let role: FamilyMemberRole
    let nickname: String?
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case userId = "user_id"
        case role
        case nickname
        case joinedAt = "joined_at"
    }
}

enum FamilyMemberRole: String, Codable {
    case admin = "admin"
    case parent = "parent"
    case child = "child"
}

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

struct JoinFamilyResult {
    let family: Family
    let member: FamilyMember
}
