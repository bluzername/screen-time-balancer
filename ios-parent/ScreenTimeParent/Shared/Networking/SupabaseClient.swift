// SupabaseClient.swift
// Screen Time Parent
//
// Supabase client singleton and configuration

import Foundation
import Supabase

// MARK: - Supabase Client Singleton

class SupabaseClientManager {
    static let shared = SupabaseClientManager()

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    // MARK: - Authentication Helpers

    var currentUser: User? {
        try? client.auth.session.user
    }

    var currentUserId: UUID? {
        guard let user = currentUser else { return nil }
        return UUID(uuidString: user.id.uuidString)
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    // MARK: - Token Management

    func getAccessToken() async throws -> String {
        let session = try await client.auth.session
        return session.accessToken
    }

    func refreshSession() async throws {
        try await client.auth.refreshSession()
    }

    // MARK: - Realtime Helpers

    func createRealtimeChannel(name: String) -> RealtimeChannelV2 {
        client.realtime.channel(name)
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .notFound:
            return "Resource not found"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Result Extension

extension Result where Success == Void {
    static var success: Result {
        .success(())
    }
}

// MARK: - Date Formatting Helpers

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension String {
    var dateFromISO8601: Date? {
        DateFormatter.iso8601Full.date(from: self) ??
        DateFormatter.iso8601.date(from: self)
    }
}

extension Date {
    var iso8601String: String {
        DateFormatter.iso8601.string(from: self)
    }

    var dateOnlyString: String {
        DateFormatter.dateOnly.string(from: self)
    }
}
