// RetryManager+Shared.swift
// Screen Time Parent
//
// Shared instance of RetryManager for network operations

import Foundation

extension RetryManager {
    static let shared = RetryManager(maxAttempts: 3, baseDelay: 1.0)
}
