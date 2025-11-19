// FamilyViewModel.swift
// Screen Time Parent
//
// Family management business logic

import Foundation
import SwiftUI

@MainActor
class FamilyViewModel: ObservableObject {
    @Published var families: [FamilyOverview] = []
    @Published var selectedFamily: FamilyWithMembers?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingCreateFamily = false
    @Published var showingInviteCode = false
    @Published var realtimeConnected = false

    private let familyRepository: FamilyRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private var realtimeManager: RealtimeManager?

    init(familyRepository: FamilyRepositoryProtocol = FamilyRepository(),
         authRepository: AuthRepositoryProtocol = AuthRepository()) {
        self.familyRepository = familyRepository
        self.authRepository = authRepository
    }

    // MARK: - Load Data

    func loadFamilies() {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                families = try await familyRepository.getUserFamilies()

                // Auto-select first family
                if let firstFamily = families.first {
                    await loadFamilyDetails(familyId: firstFamily.id)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func loadFamilyDetails(familyId: UUID) async {
        do {
            let family = try await familyRepository.getFamily(id: familyId)
            let members = try await familyRepository.getFamilyMembers(familyId: familyId)
            let devices = try await familyRepository.getDevices(familyId: familyId)

            selectedFamily = FamilyWithMembers(
                family: family,
                members: members,
                devices: devices
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create Family

    func createFamily(name: String) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                guard let currentUser = try await authRepository.getCurrentUser() else {
                    errorMessage = "Not authenticated"
                    return
                }

                let family = try await familyRepository.createFamily(
                    name: name,
                    createdBy: currentUser.id
                )

                // Add creator as admin
                let request = JoinFamilyRequest(
                    familyId: family.id,
                    userId: currentUser.id,
                    role: .admin,
                    nickname: nil
                )

                _ = try await familyRepository.addFamilyMember(request: request)

                // Reload families
                await loadFamilies()

                showingCreateFamily = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Update Family

    func updateFamilyName(_ name: String, familyId: UUID) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                _ = try await familyRepository.updateFamily(id: familyId, name: name)
                await loadFamilies()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Remove Member

    func removeMember(_ member: FamilyMember) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                try await familyRepository.removeFamilyMember(id: member.id)

                // Reload family details
                if let familyId = selectedFamily?.family.id {
                    await loadFamilyDetails(familyId: familyId)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Invite Code

    func copyInviteCode(_ code: String) {
        UIPasteboard.general.string = code
    }

    func shareInviteCode(_ code: String) -> String {
        """
        Join our Screen Time Balancer family!

        1. Download "Screen Time Balancer - Child" from the App Store
        2. Sign in or create an account
        3. Use invite code: \(code)

        This will link your device so we can manage screen time together.
        """
    }

    // MARK: - Realtime Subscriptions

    func setupRealtime(familyId: UUID) async {
        guard Config.enableRealtime else {
            print("⚠️ Realtime subscriptions disabled in config")
            return
        }

        realtimeManager = RealtimeManager()

        await realtimeManager?.subscribeToFamily(familyId: familyId)

        // Handle earned time updates
        realtimeManager?.onEarnedTimeUpdate = { [weak self] earnedTime in
            Task { @MainActor in
                // Reload family details to get fresh data
                await self?.loadFamilyDetails(familyId: familyId)
            }
        }

        // Handle usage session updates
        realtimeManager?.onUsageSessionUpdate = { [weak self] session in
            Task { @MainActor in
                // Reload family details
                await self?.loadFamilyDetails(familyId: familyId)
            }
        }

        // Handle rule updates
        realtimeManager?.onRuleUpdate = { [weak self] rule in
            Task { @MainActor in
                await self?.loadFamilyDetails(familyId: familyId)
            }
        }

        // Handle device status updates
        realtimeManager?.onDeviceStatusUpdate = { [weak self] device in
            Task { @MainActor in
                await self?.loadFamilyDetails(familyId: familyId)
            }
        }

        realtimeConnected = true
        print("✅ Realtime subscriptions active for family \(familyId)")
    }

    func disconnectRealtime() async {
        await realtimeManager?.disconnect()
        realtimeManager = nil
        realtimeConnected = false
        print("📡 Disconnected from realtime")
    }
}
