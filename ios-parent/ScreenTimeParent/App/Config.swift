// Config.swift
// Screen Time Parent
//
// Supabase configuration and app constants

import Foundation

enum Config {
    // MARK: - Supabase Configuration
    // TODO: Replace with your actual Supabase project credentials
    // Get these from: Supabase Dashboard → Settings → API

    static let supabaseURL = URL(string: "https://your-project-ref.supabase.co")!
    static let supabaseAnonKey = "your-anon-key-here"

    // MARK: - App Configuration

    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - Feature Flags

    static let enableBiometricAuth = true
    static let enableRealtime = true
    static let enableOfflineMode = true

    // MARK: - Sync Configuration

    static let syncIntervalSeconds: TimeInterval = 300 // 5 minutes
    static let usageReportDays = 7
    static let maxOfflineQueueSize = 100

    // MARK: - Rule Defaults

    static let defaultRequiredEducationalMinutes = 30
    static let defaultMaxRecreationalMinutes = 120
    static let defaultRuleStartTime = "06:00:00"
    static let defaultRuleEndTime = "21:00:00"

    // MARK: - Environment

    enum Environment {
        case development
        case staging
        case production

        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }

    // MARK: - Validation

    static func validateConfiguration() -> Bool {
        guard supabaseURL.absoluteString != "https://your-project-ref.supabase.co" else {
            print("⚠️ WARNING: Supabase URL not configured. Please update Config.swift")
            return false
        }

        guard supabaseAnonKey != "your-anon-key-here" else {
            print("⚠️ WARNING: Supabase anon key not configured. Please update Config.swift")
            return false
        }

        return true
    }
}

// MARK: - App Constants

enum AppConstants {
    static let familyNameMinLength = 2
    static let familyNameMaxLength = 50
    static let inviteCodeLength = 8

    static let minEducationalMinutes = 0
    static let maxEducationalMinutes = 240
    static let minRecreationalMinutes = 0
    static let maxRecreationalMinutes = 480

    static let passwordMinLength = 8
    static let nameMinLength = 2
    static let nameMaxLength = 50
}

// MARK: - Error Messages

enum ErrorMessages {
    static let networkError = "Network connection error. Please check your internet connection."
    static let authenticationError = "Authentication failed. Please try again."
    static let invalidInviteCode = "Invalid invite code. Please check and try again."
    static let genericError = "An error occurred. Please try again."
    static let configurationError = "App configuration error. Please contact support."
}
