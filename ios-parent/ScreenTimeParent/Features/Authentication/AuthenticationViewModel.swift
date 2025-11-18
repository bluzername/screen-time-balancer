// AuthenticationViewModel.swift
// Screen Time Parent - Authentication logic

import Foundation
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: UserProfile?

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol = AuthRepository()) {
        self.authRepository = authRepository
    }

    func checkAuthStatus() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let user = try await authRepository.getCurrentUser()
                currentUser = user
                isAuthenticated = true
            } catch {
                isAuthenticated = false
                currentUser = nil
            }
        }
    }

    func signUp(email: String, password: String, fullName: String) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                let user = try await authRepository.signUp(
                    email: email,
                    password: password,
                    fullName: fullName,
                    role: .parent
                )
                currentUser = user
                isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signIn(email: String, password: String) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                let user = try await authRepository.signIn(email: email, password: password)
                currentUser = user
                isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() {
        Task {
            do {
                try await authRepository.signOut()
                isAuthenticated = false
                currentUser = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
