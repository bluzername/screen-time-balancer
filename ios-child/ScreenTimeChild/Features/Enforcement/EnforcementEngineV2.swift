// EnforcementEngineV2.swift
// Screen Time Child
//
// Refactored enforcement engine with proper token management and concurrency

import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Main enforcement engine - handles app blocking and time tracking
/// Uses @MainActor for thread safety with UI updates
@MainActor
class EnforcementEngineV2: ObservableObject {

    // MARK: - Published State

    @Published private(set) var currentRule: ScreenTimeRule?
    @Published private(set) var earnedTime: EarnedTime?
    @Published private(set) var isRecreationalAllowed = false
    @Published private(set) var educationalTimeToday = 0
    @Published private(set) var recreationalTimeToday = 0
    @Published private(set) var enforcementState: EnforcementState = .loading

    // MARK: - Dependencies

    private let rulesRepository: RulesRepository
    private let usageRepository: UsageRepository
    private let appsRepository: AppsRepository
    private let tokenStorage: AppTokenStorage
    private let sharedData: SharedDataManager

    // MARK: - State Management

    private var currentSession: SessionState?
    private var syncTask: Task<Void, Never>?
    private var trackingTask: Task<Void, Never>?

    // MARK: - Family Controls

    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared

    // MARK: - Initialization

    init(
        rulesRepository: RulesRepository = RulesRepository(),
        usageRepository: UsageRepository = UsageRepository(),
        appsRepository: AppsRepository = AppsRepository(),
        tokenStorage: AppTokenStorage = AppTokenStorage(),
        sharedData: SharedDataManager = SharedDataManager()
    ) {
        self.rulesRepository = rulesRepository
        self.usageRepository = usageRepository
        self.appsRepository = appsRepository
        self.tokenStorage = tokenStorage
        self.sharedData = sharedData

        setupExtensionCommunication()
    }

    // MARK: - Public API

    func startMonitoring() async {
        enforcementState = .loading

        await loadRulesAndApps()
        await updateEnforcement()

        startPeriodicSync()
        setupExtensionCommunication()

        enforcementState = .active
    }

    func stopMonitoring() {
        syncTask?.cancel()
        trackingTask?.cancel()
        enforcementState = .stopped
    }

    func syncWithBackend() async {
        await loadRulesAndApps()
        await updateEnforcement()
    }

    // MARK: - Private Methods

    private func loadRulesAndApps() async {
        guard let familyId = getFamilyId(),
              let childId = getChildId() else {
            print("⚠️ Missing family or child ID")
            return
        }

        do {
            // Load rules atomically
            let rules = try await rulesRepository.getRules(familyId: familyId)
            let applicableRule = findApplicableRule(rules, for: childId)

            // Load earned time
            let today = Date().dateOnlyString
            let earned = try await usageRepository.getEarnedTime(childId: childId, date: today)

            // Update state atomically on main actor
            self.currentRule = applicableRule
            self.earnedTime = earned

            // Update shared data for extension
            if let rule = applicableRule {
                sharedData.saveRequiredEducationalMinutes(rule.requiredEducationalMinutes)
            }

            print("✅ Loaded rules and earned time")

        } catch {
            print("❌ Failed to load rules: \(error.localizedDescription)")
            enforcementState = .error(error)
        }
    }

    private func updateEnforcement() async {
        guard let rule = currentRule else {
            // No rule - allow everything
            isRecreationalAllowed = true
            await unlockRecreationalApps()
            return
        }

        guard let earned = earnedTime else {
            // No data - be conservative and lock
            isRecreationalAllowed = false
            await lockRecreationalApps()
            return
        }

        // Check if requirement is met
        let requirementMet = earned.educationalMinutes >= rule.requiredEducationalMinutes

        // Update state atomically
        self.isRecreationalAllowed = requirementMet
        self.educationalTimeToday = earned.educationalMinutes
        self.recreationalTimeToday = earned.recreationalMinutesUsed

        // Apply enforcement
        if requirementMet {
            await unlockRecreationalApps()
        } else {
            await lockRecreationalApps()
        }
    }

    private func lockRecreationalApps() async {
        guard center.authorizationStatus == .approved else {
            print("⚠️ Screen Time authorization not approved")
            return
        }

        guard tokenStorage.hasRecreationalApps() else {
            print("⚠️ No recreational apps configured")
            return
        }

        // Use stored application tokens
        let recreationalTokens = tokenStorage.getRecreationalTokens()

        // Apply shield using proper tokens
        store.shield.applications = recreationalTokens
        store.shield.applicationCategories = nil

        print("🔒 Locked \(recreationalTokens.count) recreational apps")
    }

    private func unlockRecreationalApps() async {
        guard center.authorizationStatus == .approved else { return }

        // Remove all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        print("🔓 Unlocked recreational apps")
    }

    // MARK: - Session Tracking

    func startSession(for category: AppCategory) async throws {
        // Prevent concurrent session starts
        guard currentSession == nil else {
            print("⚠️ Session already in progress")
            return
        }

        guard let childId = getChildId(),
              let deviceId = getDeviceId() else {
            throw EnforcementError.missingConfiguration
        }

        let now = Date()
        let session = SessionState(
            startTime: now,
            category: category
        )

        self.currentSession = session

        print("▶️ Started \(category) session")
    }

    func endSession() async throws {
        guard let session = currentSession else {
            print("⚠️ No active session to end")
            return
        }

        let endTime = Date()
        let duration = Int(endTime.timeIntervalSince(session.startTime))

        print("⏹️ Ended session: \(duration)s (\(duration/60) min)")

        // Clear session atomically
        self.currentSession = nil

        // Recalculate earned time
        await loadRulesAndApps()
        await updateEnforcement()
    }

    // MARK: - Periodic Sync

    private func startPeriodicSync() {
        // Cancel existing task
        syncTask?.cancel()

        // Start new periodic sync task
        syncTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Config.syncIntervalSeconds * 1_000_000_000))

                guard !Task.isCancelled else { break }

                await self?.syncWithBackend()
            }
        }
    }

    // MARK: - Extension Communication

    private func setupExtensionCommunication() {
        NotificationCenter.default.addObserver(
            forName: .educationalProgressUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let progress = notification.object as? EducationalProgress else { return }

            Task { @MainActor in
                self.educationalTimeToday = progress.currentMinutes
                await self.updateEnforcement()
            }
        }
    }

    // MARK: - Helper Methods

    private func findApplicableRule(_ rules: [ScreenTimeRule], for childId: UUID) -> ScreenTimeRule? {
        // Find active rule for this child
        return rules.first { rule in
            rule.isActive && rule.isActiveNow() && (rule.childId == childId || rule.childId == nil)
        }
    }

    private func getFamilyId() -> UUID? {
        guard let familyIdString = UserDefaults.standard.string(forKey: "family_id") else {
            return nil
        }
        return UUID(uuidString: familyIdString)
    }

    private func getChildId() -> UUID? {
        guard let childIdString = UserDefaults.standard.string(forKey: "child_id") else {
            return nil
        }
        return UUID(uuidString: childIdString)
    }

    private func getDeviceId() -> UUID? {
        guard let deviceIdString = UserDefaults.standard.string(forKey: "device_id") else {
            return nil
        }
        return UUID(uuidString: deviceIdString)
    }
}

// MARK: - Supporting Types

enum EnforcementState: Equatable {
    case loading
    case active
    case stopped
    case error(Error)

    static func == (lhs: EnforcementState, rhs: EnforcementState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
             (.active, .active),
             (.stopped, .stopped):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

struct SessionState {
    let id = UUID()
    let startTime: Date
    let category: AppCategory
}

enum EnforcementError: LocalizedError {
    case missingConfiguration
    case sessionInProgress
    case noActiveSession
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Device not properly configured"
        case .sessionInProgress:
            return "A session is already in progress"
        case .noActiveSession:
            return "No active session to end"
        case .authorizationDenied:
            return "Screen Time authorization denied"
        }
    }
}
