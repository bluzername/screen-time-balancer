// RulesRepository.swift
// Screen Time Parent - Rules and apps data access

import Foundation
import Supabase

// MARK: - Rules Repository

protocol RulesRepositoryProtocol {
    func getRules(familyId: UUID) async throws -> [ScreenTimeRule]
    func createRule(_ request: CreateRuleRequest) async throws -> ScreenTimeRule
    func updateRule(id: UUID, _ request: UpdateRuleRequest) async throws -> ScreenTimeRule
    func deleteRule(id: UUID) async throws
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

    func createRule(_ request: CreateRuleRequest) async throws -> ScreenTimeRule {
        return try await client.database
            .from("screen_time_rules")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
    }

    func updateRule(id: UUID, _ request: UpdateRuleRequest) async throws -> ScreenTimeRule {
        return try await client.database
            .from("screen_time_rules")
            .update(request)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteRule(id: UUID) async throws {
        try await client.database
            .from("screen_time_rules")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Apps Repository

protocol AppsRepositoryProtocol {
    func getApps(familyId: UUID) async throws -> [App]
    func createApp(_ request: CreateAppRequest) async throws -> App
    func updateApp(id: UUID, _ request: UpdateAppRequest) async throws -> App
    func deleteApp(id: UUID) async throws
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

    func createApp(_ request: CreateAppRequest) async throws -> App {
        return try await client.database
            .from("apps")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
    }

    func updateApp(id: UUID, _ request: UpdateAppRequest) async throws -> App {
        return try await client.database
            .from("apps")
            .update(request)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteApp(id: UUID) async throws {
        try await client.database
            .from("apps")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Usage Repository

protocol UsageRepositoryProtocol {
    func getUsageSessions(childId: UUID, date: String) async throws -> [UsageSession]
    func getDailySummary(childId: UUID, date: String) async throws -> DailyUsageSummary?
    func getEarnedTime(childId: UUID, date: String) async throws -> EarnedTime?
    func getEnforcementStatus(childId: UUID) async throws -> EnforcementStatus?
}

class UsageRepository: UsageRepositoryProtocol {
    private let client = SupabaseClientManager.shared.client

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

    func getDailySummary(childId: UUID, date: String) async throws -> DailyUsageSummary? {
        return try await client.database
            .from("daily_usage_summary")
            .select()
            .eq("child_id", value: childId.uuidString)
            .eq("date", value: date)
            .maybeSingle()
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

    func getEnforcementStatus(childId: UUID) async throws -> EnforcementStatus? {
        return try await client.database
            .from("current_enforcement_status")
            .select()
            .eq("child_id", value: childId.uuidString)
            .maybeSingle()
            .execute()
            .value
    }
}
