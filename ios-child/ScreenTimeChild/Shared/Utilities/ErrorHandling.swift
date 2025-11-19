// ErrorHandling.swift
// Screen Time Parent
//
// Comprehensive error handling framework

import Foundation

// MARK: - App Error

enum AppError: LocalizedError {
    // Authentication
    case authenticationFailed(reason: String)
    case unauthorized
    case sessionExpired
    case invalidCredentials

    // Network
    case networkUnavailable
    case requestTimeout
    case serverError(statusCode: Int)
    case rateLimited(retryAfter: TimeInterval?)

    // Data
    case dataCorrupted
    case decodingFailed(Error)
    case validationFailed(String)
    case missingData(String)

    // Family
    case familyNotFound
    case invalidInviteCode
    case alreadyMember
    case memberNotFound

    // Configuration
    case configurationError(String)
    case missingCredentials

    // Unknown
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        // Authentication
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .sessionExpired:
            return "Your session has expired. Please sign in again"
        case .invalidCredentials:
            return "Invalid email or password"

        // Network
        case .networkUnavailable:
            return "No internet connection. Please check your network settings"
        case .requestTimeout:
            return "Request timed out. Please try again"
        case .serverError(let code):
            return "Server error (\(code)). Please try again later"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please wait \(Int(seconds)) seconds"
            }
            return "Too many requests. Please wait a moment"

        // Data
        case .dataCorrupted:
            return "Data is corrupted. Please try refreshing"
        case .decodingFailed:
            return "Failed to process server response"
        case .validationFailed(let message):
            return message
        case .missingData(let field):
            return "Missing required data: \(field)"

        // Family
        case .familyNotFound:
            return "Family not found"
        case .invalidInviteCode:
            return "Invalid invite code. Please check and try again"
        case .alreadyMember:
            return "You're already a member of this family"
        case .memberNotFound:
            return "Family member not found"

        // Configuration
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .missingCredentials:
            return "App not configured. Please check configuration"

        // Unknown
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .sessionExpired:
            return "Please sign in again to continue"
        case .invalidCredentials:
            return "Check your email and password and try again"
        case .rateLimited:
            return "Please wait a moment before trying again"
        case .invalidInviteCode:
            return "Ask the family admin for a valid invite code"
        case .configurationError, .missingCredentials:
            return "Contact support for help"
        default:
            return "Please try again. If the problem persists, contact support"
        }
    }

    var category: ErrorCategory {
        switch self {
        case .authenticationFailed, .unauthorized, .sessionExpired, .invalidCredentials:
            return .authentication
        case .networkUnavailable, .requestTimeout, .serverError, .rateLimited:
            return .network
        case .dataCorrupted, .decodingFailed, .validationFailed, .missingData:
            return .data
        case .familyNotFound, .invalidInviteCode, .alreadyMember, .memberNotFound:
            return .business
        case .configurationError, .missingCredentials:
            return .configuration
        case .unknown:
            return .unknown
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .requestTimeout, .rateLimited:
            return true
        case .sessionExpired, .invalidCredentials:
            return true
        case .dataCorrupted, .decodingFailed:
            return false
        default:
            return false
        }
    }
}

enum ErrorCategory {
    case authentication
    case network
    case data
    case business
    case configuration
    case unknown
}

// MARK: - Error Handler

@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var errorLog: [ErrorLogEntry] = []

    private let maxLogEntries = 100

    func handle(_ error: Error, context: String = "") {
        let appError = convertToAppError(error)

        // Log error
        let logEntry = ErrorLogEntry(
            error: appError,
            context: context,
            timestamp: Date()
        )
        logError(logEntry)

        // Set current error for UI
        currentError = appError

        // Log to console if enabled
        if Config.enableLogging {
            print("❌ Error in \(context): \(appError.localizedDescription)")
        }
    }

    func handleSilently(_ error: Error, context: String = "") {
        let appError = convertToAppError(error)
        let logEntry = ErrorLogEntry(
            error: appError,
            context: context,
            timestamp: Date()
        )
        logError(logEntry)

        if Config.enableLogging {
            print("⚠️ Silent error in \(context): \(appError.localizedDescription)")
        }
    }

    func clearError() {
        currentError = nil
    }

    private func logError(_ entry: ErrorLogEntry) {
        errorLog.append(entry)

        // Keep only recent entries
        if errorLog.count > maxLogEntries {
            errorLog.removeFirst(errorLog.count - maxLogEntries)
        }
    }

    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                return .unauthorized
            case .notFound:
                return .familyNotFound
            case .networkError(let networkError):
                return .networkUnavailable
            case .decodingError(let decodingError):
                return .decodingFailed(decodingError)
            default:
                return .unknown(error)
            }
        }

        return .unknown(error)
    }

    // MARK: - Error Statistics

    func errorsByCategory() -> [ErrorCategory: Int] {
        var counts: [ErrorCategory: Int] = [:]
        for entry in errorLog {
            counts[entry.error.category, default: 0] += 1
        }
        return counts
    }

    func recentErrors(limit: Int = 10) -> [ErrorLogEntry] {
        Array(errorLog.suffix(limit))
    }
}

struct ErrorLogEntry: Identifiable {
    let id = UUID()
    let error: AppError
    let context: String
    let timestamp: Date
}

// MARK: - Retry Logic

actor RetryManager {
    private var attemptCounts: [String: Int] = [:]
    private let maxAttempts: Int
    private let baseDelay: TimeInterval

    init(maxAttempts: Int = 3, baseDelay: TimeInterval = 1.0) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
    }

    /// Execute operation with exponential backoff retry
    func execute<T>(
        operation: String,
        work: @Sendable () async throws -> T
    ) async throws -> T {
        let currentAttempts = attemptCounts[operation, default: 0]

        guard currentAttempts < maxAttempts else {
            attemptCounts[operation] = 0
            throw AppError.requestTimeout
        }

        do {
            let result = try await work()
            attemptCounts[operation] = 0 // Reset on success
            return result
        } catch {
            attemptCounts[operation] = currentAttempts + 1

            // Don't retry certain errors
            if let appError = error as? AppError, !appError.isRecoverable {
                attemptCounts[operation] = 0
                throw error
            }

            // Calculate exponential backoff delay
            let delay = baseDelay * pow(2.0, Double(currentAttempts))
            let jitter = Double.random(in: 0...0.1) * delay
            let totalDelay = delay + jitter

            print("🔄 Retry attempt \(currentAttempts + 1)/\(maxAttempts) for \(operation) after \(String(format: "%.1f", totalDelay))s")

            try await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))

            // Recursive retry
            return try await execute(operation: operation, work: work)
        }
    }

    func reset(operation: String) {
        attemptCounts[operation] = 0
    }

    func resetAll() {
        attemptCounts.removeAll()
    }
}

// MARK: - Error Alert Helper

import SwiftUI

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        alert(
            error.wrappedValue?.errorDescription ?? "Error",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            actions: {
                Button("OK") {
                    error.wrappedValue = nil
                }
            },
            message: {
                if let recovery = error.wrappedValue?.recoverySuggestion {
                    Text(recovery)
                }
            }
        )
    }
}

// MARK: - Network Error Handling

extension URLError {
    var appError: AppError {
        switch self.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .requestTimeout
        case .cannotFindHost, .cannotConnectToHost:
            return .serverError(statusCode: 0)
        default:
            return .unknown(self)
        }
    }
}
