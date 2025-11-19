// AuthRepository.swift
// Screen Time Parent
//
// Authentication repository handling user authentication

import Foundation
import Supabase

protocol AuthRepositoryProtocol {
    func signUp(email: String, password: String, fullName: String, role: UserRole) async throws -> UserProfile
    func signIn(email: String, password: String) async throws -> UserProfile
    func signOut() async throws
    func getCurrentUser() async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws -> UserProfile
    func resetPassword(email: String) async throws
}

class AuthRepository: AuthRepositoryProtocol {
    private let client = SupabaseClientManager.shared.client

    // MARK: - Sign Up

    func signUp(email: String, password: String, fullName: String, role: UserRole) async throws -> UserProfile {
        return try await RetryManager.shared.execute(operation: "AuthRepository.signUp") {
            do {
                // Sign up user with Supabase Auth
                let response = try await self.client.auth.signUp(
                    email: email,
                    password: password,
                    data: [
                        "full_name": .string(fullName),
                        "role": .string(role.rawValue)
                    ]
                )

                guard let user = response.user else {
                    throw APIError.invalidResponse
                }

                // Create user profile in database
                let profile = UserProfile(
                    id: UUID(uuidString: user.id.uuidString)!,
                    email: email,
                    fullName: fullName,
                    role: role,
                    dateOfBirth: nil,
                    avatarUrl: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                // Insert profile into database
                try await self.client.database
                    .from("user_profiles")
                    .insert(profile)
                    .execute()

                return profile

            } catch {
                ErrorHandler.shared.handleSilently(error, context: "AuthRepository.signUp")
                throw APIError.networkError(error)
            }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> UserProfile {
        return try await RetryManager.shared.execute(operation: "AuthRepository.signIn") {
            do {
                // Sign in with Supabase Auth
                let session = try await self.client.auth.signIn(
                    email: email,
                    password: password
                )

                // Fetch user profile
                let userId = session.user.id.uuidString

                let response: UserProfile = try await self.client.database
                    .from("user_profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value

                return response

            } catch {
                ErrorHandler.shared.handleSilently(error, context: "AuthRepository.signIn")
                throw APIError.networkError(error)
            }
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Get Current User

    func getCurrentUser() async throws -> UserProfile {
        do {
            let session = try await client.auth.session
            let userId = session.user.id.uuidString

            let response: UserProfile = try await client.database
                .from("user_profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            return response

        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Update Profile

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        do {
            let response: UserProfile = try await client.database
                .from("user_profiles")
                .update(profile)
                .eq("id", value: profile.id.uuidString)
                .single()
                .execute()
                .value

            return response

        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Reset Password

    func resetPassword(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Check Auth Status

    func checkAuthStatus() async -> Bool {
        do {
            _ = try await client.auth.session
            return true
        } catch {
            return false
        }
    }

    // MARK: - Refresh Session

    func refreshSession() async throws {
        do {
            try await client.auth.refreshSession()
        } catch {
            throw APIError.networkError(error)
        }
    }
}
