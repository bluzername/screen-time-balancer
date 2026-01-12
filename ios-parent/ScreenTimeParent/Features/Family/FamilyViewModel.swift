// FamilyViewModel.swift
// Screen Time Parent
//
// Family management business logic

import Foundation
import SwiftUI
import Combine

@MainActor
class FamilyViewModel: ObservableObject {
    @Published var families: [FamilyOverview] = []
    @Published var selectedFamily: FamilyWithMembers?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingCreateFamily = false
    @Published var showingInviteCode = false
    @Published var realtimeConnected = false
    @Published var isPollingActive = false

    private let familyRepository: FamilyRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private var realtimeManager: RealtimeManager?

    // Polling support
    private var pollingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(familyRepository: FamilyRepositoryProtocol = FamilyRepository(),
         authRepository: AuthRepositoryProtocol = AuthRepository()) {
        self.familyRepository = familyRepository
        self.authRepository = authRepository

        // Listen for app becoming active to refresh data
        setupForegroundRefresh()
    }

    deinit {
        pollingTimer?.invalidate()
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

    // MARK: - Polling (Alternative to Realtime)

    func startPolling(familyId: UUID) {
        guard Config.enablePolling else {
            print("⚠️ Polling disabled in config")
            return
        }

        // Stop any existing polling
        stopPolling()

        // Start periodic polling
        pollingTimer = Timer.scheduledTimer(withTimeInterval: Config.syncIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.pollFamilyData(familyId: familyId)
            }
        }

        isPollingActive = true
        print("🔄 Polling started (interval: \(Config.syncIntervalSeconds)s)")

        // Initial fetch
        Task {
            await pollFamilyData(familyId: familyId)
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPollingActive = false
        print("🔄 Polling stopped")
    }

    private func pollFamilyData(familyId: UUID) async {
        // Silent refresh - don't show loading indicator for background polling
        do {
            let family = try await familyRepository.getFamily(id: familyId)
            let members = try await familyRepository.getFamilyMembers(familyId: familyId)
            let devices = try await familyRepository.getDevices(familyId: familyId)

            selectedFamily = FamilyWithMembers(
                family: family,
                members: members,
                devices: devices
            )

            if Config.enableLogging {
                print("🔄 Polled family data successfully")
            }
        } catch {
            // Don't show error for background polling failures
            if Config.enableLogging {
                print("⚠️ Polling failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Foreground Refresh

    private func setupForegroundRefresh() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshOnForeground()
                }
            }
            .store(in: &cancellables)
    }

    private func refreshOnForeground() async {
        guard let familyId = selectedFamily?.family.id else { return }

        if Config.enableLogging {
            print("📱 App entered foreground - refreshing data")
        }

        await pollFamilyData(familyId: familyId)
    }

    // MARK: - Sync Mode Setup

    /// Call this instead of setupRealtime when the family is selected
    /// Automatically chooses realtime or polling based on config
    func setupSync(familyId: UUID) async {
        if Config.enableRealtime {
            await setupRealtime(familyId: familyId)
        } else if Config.enablePolling {
            startPolling(familyId: familyId)
        }
    }

    func disconnectSync() async {
        if Config.enableRealtime {
            await disconnectRealtime()
        }
        stopPolling()
    }
}
