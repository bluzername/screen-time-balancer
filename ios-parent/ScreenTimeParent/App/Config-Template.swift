// Config.swift
// Screen Time Parent
//
// IMPORTANT: This is a template file!
// 1. Copy this file to Config.swift (without -Template suffix)
// 2. Replace placeholder values with your actual Supabase credentials
// 3. DO NOT commit Config.swift to version control!
//
// Configuration with environment variable support

import Foundation

enum Config {
    // MARK: - Environment

    enum Environment: String {
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
    /// Get this from: https://app.supabase.com/project/_/settings/api
    static let supabaseURL: URL = {
        // Try to read from environment variable first
        if let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let url = URL(string: urlString) {
            return url
        }

        // Fall back to hardcoded value (replace with your actual URL!)
        // Format: https://YOUR-PROJECT-REF.supabase.co
        guard let url = URL(string: "https://your-project-ref.supabase.co") else {
            fatalError("Invalid Supabase URL configuration")
        }
        return url
    }()

    /// Supabase Anonymous Key
    /// Get this from: https://app.supabase.com/project/_/settings/api
    static let supabaseAnonKey: String = {
        // Try to read from environment variable first
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return key
        }

        // Fall back to hardcoded value (replace with your actual key!)
        return "your-anon-key-here"
    }()

    // MARK: - App Configuration

    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.screentimeparent"

    // MARK: - Sync Configuration

    static let syncIntervalSeconds: TimeInterval = {
        if let interval = ProcessInfo.processInfo.environment["PARENT_SYNC_INTERVAL_SECONDS"],
           let seconds = TimeInterval(interval) {
            return seconds
        }
        return 60 // Default: 1 minute
    }()

    // MARK: - Feature Flags

    static let enableRealtime: Bool = {
        if let enabled = ProcessInfo.processInfo.environment["PARENT_ENABLE_REALTIME"] {
            return enabled.lowercased() == "true"
        }
        return true // Default: enabled
    }()

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

    // MARK: - Validation

    static func validateConfiguration() -> ConfigurationValidation {
        var errors: [String] = []

        // Check Supabase URL
        if supabaseURL.absoluteString.contains("your-project-ref") {
            errors.append("Supabase URL not configured. Please update Config.swift with your project URL.")
        }

        // Check Supabase key
        if supabaseAnonKey.contains("your-anon-key") {
            errors.append("Supabase anonymous key not configured. Please update Config.swift with your anon key.")
        }

        // Check key length (Supabase keys are typically very long)
        if supabaseAnonKey.count < 100 {
            errors.append("Supabase anonymous key appears invalid (too short).")
        }

        let isValid = errors.isEmpty
        return ConfigurationValidation(isValid: isValid, errors: errors)
    }

    static func printConfiguration() {
        guard enableLogging else { return }

        print("""
        ================================
        Screen Time Parent - Configuration
        ================================
        Environment: \(Environment.current.rawValue)
        App Version: \(appVersion) (\(buildNumber))
        Bundle ID: \(bundleIdentifier)

        Supabase:
        - URL: \(supabaseURL.absoluteString)
        - Key: \(supabaseAnonKey.prefix(20))...(hidden)

        Settings:
        - Sync Interval: \(syncIntervalSeconds)s
        - Realtime: \(enableRealtime)
        - Logging: \(enableLogging)
        - Analytics: \(enableAnalytics)
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
