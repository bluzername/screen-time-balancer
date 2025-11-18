// Repositories.swift
// Screen Time Child
//
// Data access layer for all backend operations

import Foundation
import Supabase

// MARK: - Rules Repository

protocol RulesRepositoryProtocol {
    func getRules(familyId: UUID) async throws -> [ScreenTimeRule]
}

class RulesRepository: RulesRepositoryProtocol {
    private let client = SupabaseClientManager.shared.client

    func getRules(familyId: UUID) async throws -> [ScreenTimeRule] {
        return try await client.database
            .from("screen_time_rules")
            .select()
            .eq("family_id", value: familyId.uuidString)
            .order("priority", ascending: false)
            .execute()
            .value
    }
}

// MARK: - Apps Repository

protocol AppsRepositoryProtocol {
    func getApps(familyId: UUID) async throws -> [App]
}

class AppsRepository: AppsRepositoryProtocol {
    private let client = SupabaseClientManager.shared.client

    func getApps(familyId: UUID) async throws -> [App] {
        return try await client.database
            .from("apps")
            .select()
            .eq("family_id", value: familyId.uuidString)
            .order("app_name", ascending: true)
            .execute()
            .value
    }
}

// MARK: - Usage Repository

protocol UsageRepositoryProtocol {
    func createSession(_ request: CreateUsageSessionRequest) async throws -> UsageSession
    func updateSession(_ sessionId: UUID, _ request: UpdateUsageSessionRequest) async throws -> UsageSession
    func getEarnedTime(childId: UUID, date: String) async throws -> EarnedTime?
    func getUsageSessions(childId: UUID, date: String) async throws -> [UsageSession]
}

class UsageRepository: UsageRepositoryProtocol {
    private let client = SupabaseClientManager.shared.client

    func createSession(_ request: CreateUsageSessionRequest) async throws -> UsageSession {
        return try await client.database
            .from("usage_sessions")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
    }

    func updateSession(_ sessionId: UUID, _ request: UpdateUsageSessionRequest) async throws -> UsageSession {
        return try await client.database
            .from("usage_sessions")
            .update(request)
            .eq("id", value: sessionId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func getEarnedTime(childId: UUID, date: String) async throws -> EarnedTime? {
        return try await client.database
            .from("earned_time")
            .select()
            .eq("child_id", value: childId.uuidString)
            .eq("date", value: date)
            .maybeSingle()
            .execute()
            .value
    }

    func getUsageSessions(childId: UUID, date: String) async throws -> [UsageSession] {
        return try await client.database
            .from("usage_sessions")
            .select()
            .eq("child_id", value: childId.uuidString)
            .eq("date", value: date)
            .order("started_at", ascending: false)
            .execute()
            .value
    }
}
