// Validators.swift
// Screen Time Parent
//
// Input validation and security utilities

import Foundation

// MARK: - Email Validator

struct EmailValidator {
    static func isValid(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    static func validationError(for email: String) -> String? {
        guard !email.isEmpty else {
            return "Email is required"
        }

        guard email.count <= 254 else {
            return "Email is too long"
        }

        guard isValid(email) else {
            return "Please enter a valid email address"
        }

        return nil
    }
}

// MARK: - Password Validator

struct PasswordValidator {
    static let minimumLength = 8
    static let maximumLength = 128

    struct ValidationResult {
        let isValid: Bool
        let errors: [String]

        var errorMessage: String? {
            errors.isEmpty ? nil : errors.first
        }
    }

    static func validate(_ password: String, requireStrength: Bool = true) -> ValidationResult {
        var errors: [String] = []

        // Length check
        if password.isEmpty {
            errors.append("Password is required")
            return ValidationResult(isValid: false, errors: errors)
        }

        if password.count < minimumLength {
            errors.append("Password must be at least \(minimumLength) characters")
        }

        if password.count > maximumLength {
            errors.append("Password is too long")
        }

        // Strength checks (if required)
        if requireStrength {
            let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
            let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
            let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
            let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil

            if !hasLowercase {
                errors.append("Password must contain at least one lowercase letter")
            }

            if !hasUppercase && !hasNumber && !hasSpecial {
                errors.append("Password must contain at least one uppercase letter, number, or special character")
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    static func strength(_ password: String) -> PasswordStrength {
        guard password.count >= minimumLength else {
            return .weak
        }

        var score = 0

        // Length bonus
        if password.count >= 12 {
            score += 1
        }
        if password.count >= 16 {
            score += 1
        }

        // Character variety
        if password.range(of: "[a-z]", options: .regularExpression) != nil {
            score += 1
        }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            score += 1
        }
        if password.range(of: "[0-9]", options: .regularExpression) != nil {
            score += 1
        }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil {
            score += 1
        }

        if score >= 5 {
            return .strong
        } else if score >= 3 {
            return .medium
        } else {
            return .weak
        }
    }
}

enum PasswordStrength {
    case weak
    case medium
    case strong

    var color: String {
        switch self {
        case .weak:
            return "red"
        case .medium:
            return "orange"
        case .strong:
            return "green"
        }
    }

    var description: String {
        switch self {
        case .weak:
            return "Weak"
        case .medium:
            return "Medium"
        case .strong:
            return "Strong"
        }
    }
}

// MARK: - Name Validator

struct NameValidator {
    static func isValid(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 100
    }

    static func sanitize(_ name: String) -> String {
        // Remove leading/trailing whitespace
        var sanitized = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove excessive internal whitespace
        sanitized = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Remove potentially dangerous characters
        let allowedCharacterSet = CharacterSet.letters
            .union(.whitespaces)
            .union(.punctuationCharacters)
            .union(.decimalDigits)

        sanitized = String(sanitized.unicodeScalars.filter { allowedCharacterSet.contains($0) })

        return sanitized
    }

    static func validationError(for name: String) -> String? {
        let sanitized = sanitize(name)

        guard !sanitized.isEmpty else {
            return "Name is required"
        }

        guard sanitized.count <= 100 else {
            return "Name is too long"
        }

        return nil
    }
}

// MARK: - Invite Code Validator

struct InviteCodeValidator {
    static let validLength = 8

    static func isValid(_ code: String) -> Bool {
        let uppercased = code.uppercased()
        guard uppercased.count == validLength else {
            return false
        }

        // Only alphanumeric characters
        let alphanumericSet = CharacterSet.alphanumerics
        return uppercased.unicodeScalars.allSatisfy { alphanumericSet.contains($0) }
    }

    static func format(_ code: String) -> String {
        return code.uppercased().prefix(validLength).description
    }

    static func validationError(for code: String) -> String? {
        guard !code.isEmpty else {
            return "Invite code is required"
        }

        guard code.count == validLength else {
            return "Invite code must be exactly \(validLength) characters"
        }

        guard isValid(code) else {
            return "Invite code can only contain letters and numbers"
        }

        return nil
    }
}

// MARK: - Input Sanitizer

struct InputSanitizer {
    /// Sanitize text input to prevent XSS and injection attacks
    static func sanitizeText(_ text: String) -> String {
        var sanitized = text

        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")

        // Normalize newlines
        sanitized = sanitized.replacingOccurrences(of: "\r\n", with: "\n")

        // Trim excessive whitespace
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)

        return sanitized
    }

    /// Sanitize numeric input
    static func sanitizeInteger(_ text: String) -> Int? {
        let digits = text.filter { $0.isNumber }
        return Int(digits)
    }

    /// Limit text to maximum length
    static func limitLength(_ text: String, maxLength: Int) -> String {
        if text.count > maxLength {
            return String(text.prefix(maxLength))
        }
        return text
    }
}

// MARK: - Rate Limiter

@MainActor
class RateLimiter: ObservableObject {
    private var attempts: [String: [Date]] = [:]
    private let maxAttempts: Int
    private let timeWindow: TimeInterval

    init(maxAttempts: Int = 5, timeWindow: TimeInterval = 300) { // 5 attempts per 5 minutes
        self.maxAttempts = maxAttempts
        self.timeWindow = timeWindow
    }

    func checkLimit(for key: String) -> Bool {
        let now = Date()
        let cutoff = now.addingTimeInterval(-timeWindow)

        // Clean up old attempts
        attempts[key] = attempts[key]?.filter { $0 > cutoff } ?? []

        // Check if limit exceeded
        guard let count = attempts[key]?.count, count < maxAttempts else {
            return false
        }

        return true
    }

    func recordAttempt(for key: String) {
        let now = Date()
        let cutoff = now.addingTimeInterval(-timeWindow)

        // Clean up old attempts
        attempts[key] = attempts[key]?.filter { $0 > cutoff } ?? []

        // Record new attempt
        attempts[key, default: []].append(now)
    }

    func remainingAttempts(for key: String) -> Int {
        let now = Date()
        let cutoff = now.addingTimeInterval(-timeWindow)

        let recentAttempts = attempts[key]?.filter { $0 > cutoff }.count ?? 0
        return max(0, maxAttempts - recentAttempts)
    }

    func timeUntilReset(for key: String) -> TimeInterval? {
        guard let oldest = attempts[key]?.first else {
            return nil
        }

        let resetTime = oldest.addingTimeInterval(timeWindow)
        let remaining = resetTime.timeIntervalSince(Date())

        return remaining > 0 ? remaining : nil
    }

    func reset(for key: String) {
        attempts[key] = []
    }
}
