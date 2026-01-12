// Config.swift
// Screen Time Child
//
// Configuration with environment variable support

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

    static let supabaseURL: URL = {
        if let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let url = URL(string: urlString) {
            return url
        }
        guard let url = URL(string: "https://your-project-ref.supabase.co") else {
            fatalError("Invalid Supabase URL configuration")
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return key
        }
        return "your-anon-key-here"
    }()

    // MARK: - App Configuration

    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.screentimechild"

    // MARK: - Enforcement Configuration

    static let usageTrackingIntervalSeconds: TimeInterval = 10

    static let syncIntervalSeconds: TimeInterval = {
        if let interval = ProcessInfo.processInfo.environment["CHILD_SYNC_INTERVAL_SECONDS"],
           let seconds = TimeInterval(interval) {
            return seconds
        }
        return 60 // 1 minute - more responsive for rule enforcement
    }()

    static let heartbeatIntervalSeconds: TimeInterval = {
        if let interval = ProcessInfo.processInfo.environment["CHILD_HEARTBEAT_INTERVAL_SECONDS"],
           let seconds = TimeInterval(interval) {
            return seconds
        }
        return 30
    }()

    // MARK: - Feature Flags

    static let enableLocalEnforcement = true
    static let enableOfflineMode = true

    static let strictMode: Bool = {
        if let enabled = ProcessInfo.processInfo.environment["CHILD_ENABLE_STRICT_MODE"] {
            return enabled.lowercased() == "true"
        }
        return true
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
        Screen Time Child - Configuration
        ================================
        Environment: \(Environment.current)
        Version: \(appVersion) (\(buildNumber))
        Bundle ID: \(bundleIdentifier)

        Supabase:
        - URL: \(supabaseURL.absoluteString)
        - Key: \(supabaseAnonKey.prefix(20))...(hidden)

        Settings:
        - Sync Interval: \(syncIntervalSeconds)s
        - Heartbeat: \(heartbeatIntervalSeconds)s
        - Strict Mode: \(strictMode)
        - Logging: \(enableLogging)
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
