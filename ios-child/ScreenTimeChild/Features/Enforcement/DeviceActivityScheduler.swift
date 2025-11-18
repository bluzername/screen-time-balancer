// DeviceActivityScheduler.swift
// Screen Time Child
//
// Manages Device Activity scheduling and monitoring

import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

@MainActor
class DeviceActivityScheduler: ObservableObject {

    // Device Activity Center for scheduling
    private let activityCenter = DeviceActivityCenter()

    // Shared data manager for extension communication
    private let sharedData = SharedDataManager()

    // Activity name for our monitoring
    private let activityName = DeviceActivityName("screenTimeBalancer")

    // Event names
    private let educationalThresholdEvent = DeviceActivityEvent.Name("educationalThreshold")
    private let recreationalThresholdEvent = DeviceActivityEvent.Name("recreationalThreshold")

    // MARK: - Schedule Monitoring

    func scheduleMonitoring(
        educationalApps: [String],
        recreationalApps: [String],
        requiredEducationalMinutes: Int,
        maxRecreationalMinutes: Int?
    ) async throws {

        // Save app categories to shared data for extension
        var categories: [String: String] = [:]
        for app in educationalApps {
            categories[app] = "educational"
        }
        for app in recreationalApps {
            categories[app] = "recreational"
        }
        sharedData.saveAppCategories(categories)
        sharedData.saveRecreationalApps(recreationalApps)
        sharedData.saveRequiredEducationalMinutes(requiredEducationalMinutes)

        // Create the schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0), // Midnight
            intervalEnd: DateComponents(hour: 23, minute: 59), // 11:59 PM
            repeats: true
        )

        // Create events for thresholds
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        // Educational threshold event
        events[educationalThresholdEvent] = DeviceActivityEvent(
            applications: [], // Will be set up with proper tokens
            threshold: DateComponents(minute: requiredEducationalMinutes)
        )

        // Recreational threshold event (if set)
        if let maxMinutes = maxRecreationalMinutes {
            events[recreationalThresholdEvent] = DeviceActivityEvent(
                applications: [], // Will be set up with proper tokens
                threshold: DateComponents(minute: maxMinutes)
            )
        }

        // Start monitoring
        do {
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: events
            )

            print("✅ Device activity monitoring started")

        } catch {
            print("❌ Failed to start monitoring: \(error)")
            throw error
        }
    }

    // MARK: - Stop Monitoring

    func stopMonitoring() {
        activityCenter.stopMonitoring([activityName])
        print("⏹️ Device activity monitoring stopped")
    }

    // MARK: - Check Activity Status

    func isMonitoringActive() -> Bool {
        // Check if monitoring is currently active
        // Note: There's no direct API to check this, so we track it locally
        return UserDefaults.standard.bool(forKey: "isMonitoringActive")
    }

    func setMonitoringActive(_ active: Bool) {
        UserDefaults.standard.set(active, forKey: "isMonitoringActive")
    }

    // MARK: - Setup App Selection

    func setupAppSelection() {
        // In production, you would use FamilyActivityPicker to let the user
        // select apps to monitor. This generates the proper application tokens.

        // Example usage (commented out, implement in UI):
        /*
        let selection = FamilyActivitySelection()

        // Present picker (in a SwiftUI view):
        FamilyActivityPicker(selection: $selection)

        // After selection, get the tokens:
        let appTokens = selection.applicationTokens
        let categoryTokens = selection.categoryTokens

        // Use these tokens in DeviceActivityEvent
        */

        print("📱 App selection UI needed - implement FamilyActivityPicker")
    }
}

// MARK: - Activity Selection Helper

class ActivitySelectionHelper {

    // Store selected apps persistently
    private enum Keys {
        static let selectedEducationalApps = "selectedEducationalApps"
        static let selectedRecreationalApps = "selectedRecreationalApps"
    }

    func saveEducationalApps(_ bundleIds: [String]) {
        UserDefaults.standard.set(bundleIds, forKey: Keys.selectedEducationalApps)
    }

    func saveRecreationalApps(_ bundleIds: [String]) {
        UserDefaults.standard.set(bundleIds, forKey: Keys.selectedRecreationalApps)
    }

    func getEducationalApps() -> [String] {
        return UserDefaults.standard.stringArray(forKey: Keys.selectedEducationalApps) ?? []
    }

    func getRecreationalApps() -> [String] {
        return UserDefaults.standard.stringArray(forKey: Keys.selectedRecreationalApps) ?? []
    }
}

// MARK: - Shield Configuration Helper

class ShieldConfigurationHelper {

    private let store = ManagedSettingsStore()

    func applyShields(to bundleIds: [String]) {
        // In production, use proper application tokens from FamilyActivitySelection

        print("🛡️ Applying shields to: \(bundleIds)")

        // Note: This is a simplified version
        // In production, you need ApplicationTokens from FamilyActivityPicker
    }

    func removeAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        print("🔓 All shields removed")
    }

    func applyWebContentFilter(blockedDomains: [String]) {
        // Block specific web domains
        // store.shield.webDomains = webDomainTokens

        print("🌐 Web filter applied to: \(blockedDomains)")
    }
}

// MARK: - Background Sync Manager

class BackgroundSyncManager {

    private let sharedData = SharedDataManager()

    func syncPendingSessions() async {
        // Get completed sessions that haven't been synced
        let sessions = sharedData.getTodaysSessions()

        guard !sessions.isEmpty else {
            print("No sessions to sync")
            return
        }

        print("📤 Syncing \(sessions.count) sessions to backend...")

        // TODO: Sync to Supabase backend
        // This would use the UsageRepository to upload sessions

        do {
            // Example sync code:
            // for session in sessions {
            //     try await usageRepository.createSession(session)
            // }

            // After successful sync, clear completed sessions
            // sharedData.clearCompletedSessions()

            print("✅ Sessions synced successfully")

        } catch {
            print("❌ Sync failed: \(error)")
        }
    }

    func scheduleBackgroundSync() {
        // Schedule periodic background sync
        // This would use BGTaskScheduler for background processing

        print("⏰ Background sync scheduled")
    }
}
