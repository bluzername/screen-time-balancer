// FamilyRepository.swift
// Screen Time Parent - Family data access layer

import Foundation
import Supabase

protocol FamilyRepositoryProtocol {
    func createFamily(name: String, createdBy: UUID) async throws -> Family
    func getFamily(id: UUID) async throws -> Family
    func getFamilyByInviteCode(_ code: String) async throws -> Family
    func getUserFamilies() async throws -> [FamilyOverview]
    func updateFamily(id: UUID, name: String) async throws -> Family
    func getFamilyMembers(familyId: UUID) async throws -> [FamilyMember]
    func addFamilyMember(request: JoinFamilyRequest) async throws -> FamilyMember
    func removeFamilyMember(id: UUID) async throws
    func getDevices(familyId: UUID) async throws -> [Device]
}

class FamilyRepository: FamilyRepositoryProtocol {
    private let client = SupabaseClientManager.shared.client

    func createFamily(name: String, createdBy: UUID) async throws -> Family {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.createFamily") {
            let request = CreateFamilyRequest(name: name, createdBy: createdBy)
            return try await self.client.database
                .from("families")
                .insert(request)
                .select()
                .single()
                .execute()
                .value
        }
    }

    func getFamily(id: UUID) async throws -> Family {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.getFamily") {
            try await self.client.database
                .from("families")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
        }
    }

    func getFamilyByInviteCode(_ code: String) async throws -> Family {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.getFamilyByInviteCode") {
            try await self.client.database
                .from("families")
                .select()
                .eq("invite_code", value: code)
                .single()
                .execute()
                .value
        }
    }

    func getUserFamilies() async throws -> [FamilyOverview] {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.getUserFamilies") {
            try await self.client.database
                .from("family_overview")
                .select()
                .execute()
                .value
        }
    }

    func updateFamily(id: UUID, name: String) async throws -> Family {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.updateFamily") {
            try await self.client.database
                .from("families")
                .update(["name": name])
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value
        }
    }

    func getFamilyMembers(familyId: UUID) async throws -> [FamilyMember] {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.getFamilyMembers") {
            try await self.client.database
                .from("family_members")
                .select("*, user_profiles(*)")
                .eq("family_id", value: familyId.uuidString)
                .execute()
                .value
        }
    }

    func addFamilyMember(request: JoinFamilyRequest) async throws -> FamilyMember {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.addFamilyMember") {
            try await self.client.database
                .from("family_members")
                .insert(request)
                .select()
                .single()
                .execute()
                .value
        }
    }

    func removeFamilyMember(id: UUID) async throws {
        try await RetryManager.shared.execute(operation: "FamilyRepository.removeFamilyMember") {
            try await self.client.database
                .from("family_members")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    }

    func getDevices(familyId: UUID) async throws -> [Device] {
        return try await RetryManager.shared.execute(operation: "FamilyRepository.getDevices") {
            try await self.client.database
                .from("devices")
                .select()
                .eq("family_id", value: familyId.uuidString)
                .eq("is_active", value: true)
                .execute()
                .value
        }
    }
}
