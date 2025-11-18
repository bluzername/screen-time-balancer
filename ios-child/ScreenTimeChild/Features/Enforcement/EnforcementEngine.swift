// EnforcementEngine.swift
// Screen Time Child
//
// Core enforcement logic for app blocking and time tracking

import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

@MainActor
class EnforcementEngine: ObservableObject {
    @Published var currentRule: ScreenTimeRule?
    @Published var earnedTime: EarnedTime?
    @Published var isRecreationalAllowed = false
    @Published var educationalTimeToday = 0
    @Published var recreationalTimeToday = 0

    // Repositories
    private let rulesRepository = RulesRepository()
    private let usageRepository = UsageRepository()
    private let appsRepository = AppsRepository()

    // Categorized apps
    @Published var educationalApps: [App] = []
    @Published var recreationalApps: [App] = []

    // Current session tracking
    private var currentSession: UsageSession?
    private var sessionStartTime: Date?
    private var trackingTimer: Timer?
    private var syncTimer: Timer?

    // Family Controls
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared

    // Device Activity Scheduler for real-time monitoring
    private let deviceActivityScheduler = DeviceActivityScheduler()

    // Shared data manager for extension communication
    private let sharedData = SharedDataManager()

    init() {
        startMonitoring()
        setupExtensionCommunication()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        // Load rules and apps
        Task {
            await loadRulesAndApps()
            await updateEnforcement()
        }

        // Start periodic sync
        startPeriodicSync()

        // Start usage tracking
        startUsageTracking()

        // Schedule device activity monitoring
        Task {
            await scheduleDeviceActivityMonitoring()
        }
    }

    private func setupExtensionCommunication() {
        // Listen for updates from the Device Activity Monitor extension
        NotificationCenter.default.addObserver(
            forName: .educationalProgressUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let progress = notification.object as? EducationalProgress else { return }

            // Update UI with progress from extension
            self.educationalTimeToday = progress.currentMinutes

            Task { @MainActor in
                // Update enforcement based on new progress
                await self.updateEnforcement()
            }
        }
    }

    private func scheduleDeviceActivityMonitoring() async {
        guard let rule = currentRule else { return }

        let educationalBundleIds = educationalApps.map { $0.bundleId }
        let recreationalBundleIds = recreationalApps.map { $0.bundleId }

        do {
            try await deviceActivityScheduler.scheduleMonitoring(
                educationalApps: educationalBundleIds,
                recreationalApps: recreationalBundleIds,
                requiredEducationalMinutes: rule.requiredEducationalMinutes,
                maxRecreationalMinutes: rule.maxRecreationalMinutes
            )

            // Sync initial data to shared container
            sharedData.saveRequiredEducationalMinutes(rule.requiredEducationalMinutes)
            var categories: [String: String] = [:]
            for app in educationalApps {
                categories[app.bundleId] = "educational"
            }
            for app in recreationalApps {
                categories[app.bundleId] = "recreational"
            }
            sharedData.saveAppCategories(categories)

            print("✅ Device activity monitoring scheduled")

        } catch {
            print("❌ Failed to schedule monitoring: \(error)")
        }
    }

    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: Config.syncIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncWithBackend()
            }
        }
    }

    private func startUsageTracking() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: Config.usageTrackingIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.trackCurrentUsage()
            }
        }
    }

    // MARK: - Rules and Apps Loading

    func loadRulesAndApps() async {
        guard let familyId = getFamilyId(),
              let childId = getChildId() else {
            return
        }

        do {
            // Load rules
            let rules = try await rulesRepository.getRules(familyId: familyId)
            let applicableRule = rules.first { rule in
                rule.isActive && (rule.childId == childId || rule.childId == nil)
            }
            currentRule = applicableRule

            // Load app categorizations
            let apps = try await appsRepository.getApps(familyId: familyId)
            educationalApps = apps.filter { $0.category == .educational }
            recreationalApps = apps.filter { $0.category == .recreational }

            // Load today's earned time
            let today = Date().dateOnlyString
            earnedTime = try await usageRepository.getEarnedTime(childId: childId, date: today)

        } catch {
            print("Error loading rules and apps: \(error)")
        }
    }

    // MARK: - Enforcement Logic

    func updateEnforcement() async {
        guard let rule = currentRule,
              let earned = earnedTime else {
            // No rule or earned time data - allow everything for now
            isRecreationalAllowed = true
            await unlockRecreationalApps()
            return
        }

        // Check if educational requirement is met
        let requirementMet = earned.educationalMinutes >= rule.requiredEducationalMinutes

        isRecreationalAllowed = requirementMet

        if requirementMet {
            await unlockRecreationalApps()
        } else {
            await lockRecreationalApps()
        }
    }

    private func lockRecreationalApps() async {
        guard center.authorizationStatus == .approved else { return }

        // Create shield configuration for recreational apps
        let recreationalBundleIds = Set(recreationalApps.map { $0.bundleId })

        let applications = FamilyActivitySelection()
        // Note: In a real implementation, you would need to properly convert
        // bundle IDs to ApplicationTokens. This requires using FamilyActivityPicker
        // to let the user select apps, which generates the proper tokens.

        // For MVP, we'll use a simplified approach
        store.shield.applications = applications.applicationTokens
        store.shield.applicationCategories = .all(except: .init())

        print("🔒 Locked recreational apps")
    }

    private func unlockRecreationalApps() async {
        guard center.authorizationStatus == .approved else { return }

        // Remove all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        print("🔓 Unlocked recreational apps")
    }

    // MARK: - Usage Tracking

    private func trackCurrentUsage() async {
        // In a real implementation, this would use DeviceActivityMonitor
        // to track actual app usage. For MVP, this is a placeholder.

        // Check which app is currently active (would use DeviceActivity API)
        // For now, we'll simulate tracking
        print("📊 Tracking usage...")
    }

    func startAppSession(bundleId: String, appName: String, category: AppCategory) async {
        guard let childId = getChildId(),
              let deviceId = getDeviceId() else {
            return
        }

        let startTime = Date()
        sessionStartTime = startTime

        let request = CreateUsageSessionRequest(
            childId: childId,
            deviceId: deviceId,
            bundleId: bundleId,
            appName: appName,
            category: category,
            startedAt: startTime,
            date: startTime.dateOnlyString
        )

        do {
            // Create session in backend
            // Would call API to create session
            print("📱 Started session for \(appName)")
        } catch {
            print("Error starting session: \(error)")
        }
    }

    func endAppSession() async {
        guard let startTime = sessionStartTime else { return }

        let endTime = Date()
        let duration = Int(endTime.timeIntervalSince(startTime))

        // Update session with end time and duration
        // Would call API to update session

        sessionStartTime = nil
        currentSession = nil

        // Update earned time
        await recalculateEarnedTime()
        await updateEnforcement()

        print("⏹️ Ended session. Duration: \(duration)s")
    }

    private func recalculateEarnedTime() async {
        guard let childId = getChildId() else { return }

        let today = Date().dateOnlyString

        do {
            // Fetch updated earned time from backend
            earnedTime = try await usageRepository.getEarnedTime(childId: childId, date: today)
        } catch {
            print("Error recalculating earned time: \(error)")
        }
    }

    // MARK: - Sync

    func syncWithBackend() async {
        print("🔄 Syncing with backend...")

        await loadRulesAndApps()
        await updateEnforcement()

        // Update last sync time
        UserDefaults.standard.set(Date(), forKey: "last_sync_time")
    }

    // MARK: - Helpers

    private func getFamilyId() -> UUID? {
        // Would retrieve from stored device/user info
        guard let familyIdString = UserDefaults.standard.string(forKey: "family_id") else {
            return nil
        }
        return UUID(uuidString: familyIdString)
    }

    private func getChildId() -> UUID? {
        // Would retrieve from current user session
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

    // MARK: - Cleanup

    deinit {
        trackingTimer?.invalidate()
        syncTimer?.invalidate()
    }
}

// MARK: - Device Activity Extension Support

// Note: In production, you would implement a DeviceActivityMonitor extension
// to handle actual app usage monitoring in the background.
// See Apple's Screen Time API documentation for full implementation.

extension EnforcementEngine {
    func setupDeviceActivityMonitoring() {
        // Configure device activity monitoring
        // This requires a separate app extension

        print("📲 Device activity monitoring configured")
    }
}
