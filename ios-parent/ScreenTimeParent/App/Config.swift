// Config.swift
// Screen Time Parent
//
// Supabase configuration and app constants
// Supports environment variables for secure credential management

import Foundation

enum Config {
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

    // MARK: - Supabase Configuration

    /// Supabase Project URL
    /// Priority: 1) Environment variable 2) Hardcoded value
    static let supabaseURL: URL = {
        if let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let url = URL(string: urlString) {
            return url
        }

        // Fallback to hardcoded (replace with your URL)
        guard let url = URL(string: "https://your-project-ref.supabase.co") else {
            fatalError("Invalid Supabase URL configuration")
        }
        return url
    }()

    /// Supabase Anonymous Key
    /// Priority: 1) Environment variable 2) Hardcoded value
    static let supabaseAnonKey: String = {
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return key
        }
        return "your-anon-key-here"
    }()

    // MARK: - App Configuration

    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.screentimeparent"

    // MARK: - Feature Flags

    static let enableBiometricAuth = true

    static let enableRealtime: Bool = {
        if let enabled = ProcessInfo.processInfo.environment["PARENT_ENABLE_REALTIME"] {
            return enabled.lowercased() == "true"
        }
        return false // Disabled by default - using polling instead to avoid Supabase realtime costs
    }()

    /// Enable polling as alternative to realtime subscriptions
    static let enablePolling: Bool = {
        if let enabled = ProcessInfo.processInfo.environment["PARENT_ENABLE_POLLING"] {
            return enabled.lowercased() == "true"
        }
        return true // Enabled by default
    }()

    static let enableOfflineMode = true

    static let enableLogging: Bool = {
        if let enabled = ProcessInfo.processInfo.environment["ENABLE_LOGGING"] {
            return enabled.lowercased() == "true"
        }
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    static let enableAnalytics: Bool = {
        if let enabled = ProcessInfo.processInfo.environment["ENABLE_ANALYTICS"] {
            return enabled.lowercased() == "true"
        }
        return Environment.current == .production
    }()

    // MARK: - Sync Configuration

    static let syncIntervalSeconds: TimeInterval = {
        if let interval = ProcessInfo.processInfo.environment["PARENT_SYNC_INTERVAL_SECONDS"],
           let seconds = TimeInterval(interval) {
            return seconds
        }
        return 60 // 1 minute for parent app
    }()

    static let usageReportDays = 7
    static let maxOfflineQueueSize = 100

    // MARK: - Rule Defaults

    static let defaultRequiredEducationalMinutes = 30
    static let defaultMaxRecreationalMinutes = 120
    static let defaultRuleStartTime = "06:00:00"
    static let defaultRuleEndTime = "21:00:00"

    // MARK: - Validation

    static func validateConfiguration() -> ConfigurationValidation {
        var errors: [String] = []

        if supabaseURL.absoluteString.contains("your-project-ref") {
            errors.append("Supabase URL not configured")
        }

        if supabaseAnonKey.contains("your-anon-key") {
            errors.append("Supabase anonymous key not configured")
        }

        if supabaseAnonKey.count < 100 {
            errors.append("Supabase anonymous key appears invalid")
        }

        return ConfigurationValidation(isValid: errors.isEmpty, errors: errors)
    }

    static func printConfiguration() {
        guard enableLogging else { return }

        print("""
        ================================
        Screen Time Parent - Configuration
        ================================
        Environment: \(Environment.current)
        Version: \(appVersion) (\(buildNumber))
        Bundle ID: \(bundleIdentifier)

        Supabase:
        - URL: \(supabaseURL.absoluteString)
        - Key: \(supabaseAnonKey.prefix(20))...(hidden)

        Settings:
        - Realtime: \(enableRealtime)
        - Polling: \(enablePolling)
        - Logging: \(enableLogging)
        - Analytics: \(enableAnalytics)
        - Sync Interval: \(syncIntervalSeconds)s
        ================================
        """)
    }
}

struct ConfigurationValidation {
    let isValid: Bool
    let errors: [String]

    var errorMessage: String? {
        guard !isValid else { return nil }
        return errors.joined(separator: "\n")
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

// MARK: - Error Messages (Deprecated - use ErrorHandling.swift)

enum ErrorMessages {
    static let networkError = "Network connection error. Please check your internet connection."
    static let authenticationError = "Authentication failed. Please try again."
    static let invalidInviteCode = "Invalid invite code. Please check and try again."
    static let genericError = "An error occurred. Please try again."
    static let configurationError = "App configuration error. Please contact support."
}
