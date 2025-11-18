// Config.swift
// Screen Time Child
//
// Configuration matching parent app

import Foundation

enum Config {
    // MARK: - Supabase Configuration
    // TODO: Replace with your actual Supabase project credentials
    static let supabaseURL = URL(string: "https://your-project-ref.supabase.co")!
    static let supabaseAnonKey = "your-anon-key-here"

    // MARK: - App Configuration
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - Enforcement Configuration
    static let usageTrackingIntervalSeconds: TimeInterval = 10  // Track every 10 seconds
    static let syncIntervalSeconds: TimeInterval = 300  // Sync every 5 minutes
    static let heartbeatIntervalSeconds: TimeInterval = 30  // Heartbeat every 30 seconds

    // MARK: - Feature Flags
    static let enableLocalEnforcement = true
    static let enableOfflineMode = true
    static let strictMode = true  // Block immediately if requirements not met

    static func validateConfiguration() -> Bool {
        guard supabaseURL.absoluteString != "https://your-project-ref.supabase.co" else {
            print("⚠️ WARNING: Supabase URL not configured")
            return false
        }
        guard supabaseAnonKey != "your-anon-key-here" else {
            print("⚠️ WARNING: Supabase anon key not configured")
            return false
        }
        return true
    }
}
