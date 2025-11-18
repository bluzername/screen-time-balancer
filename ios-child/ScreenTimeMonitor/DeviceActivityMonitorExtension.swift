// DeviceActivityMonitorExtension.swift
// Screen Time Monitor Extension
//
// Device Activity Monitor for real-time app usage tracking

import DeviceActivity
import Foundation
import ManagedSettings

// IMPORTANT: This extension runs in a separate process and has limited capabilities
// It cannot directly communicate with the main app except through shared containers

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // Shared data manager for communication with main app
    private let sharedData = SharedDataManager()

    // MARK: - Interval Start

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Called when a monitored activity interval starts
        // This is when a child opens an app we're tracking

        print("📱 Activity started: \(activity)")

        let category = determineCategory(for: activity)
        let bundleId = extractBundleId(from: activity.rawValue)
        let appName = extractAppName(from: activity.rawValue)

        // Record the start of this activity session
        let session = UsageSessionData(
            activityName: activity.rawValue,
            bundleId: bundleId,
            appName: appName,
            startTime: Date(),
            category: category
        )

        sharedData.saveSessionStart(session)

        // Check if this is an educational app
        if session.category == "educational" {
            // Update educational time progress
            updateEducationalProgress()
        }
    }

    // MARK: - Interval End

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Called when a monitored activity interval ends
        // This is when a child closes or switches away from an app

        print("⏹️ Activity ended: \(activity)")

        // Get the session that just ended
        if var session = sharedData.getActiveSession(for: activity.rawValue) {
            session.endTime = Date()

            // Calculate duration
            if let start = session.startTime, let end = session.endTime {
                let duration = end.timeIntervalSince(start)
                session.durationSeconds = Int(duration)
            }

            // Save completed session
            sharedData.saveCompletedSession(session)

            // Update earned time based on category
            if session.category == "educational" {
                updateEducationalProgress()
                checkAndUpdateEnforcement()
            }
        }
    }

    // MARK: - Event Will Reach Threshold

    override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)

        // Called when an event is about to reach its threshold
        // Use this to warn the user they're running out of time

        print("⚠️ Warning: Event \(event) approaching threshold for \(activity)")

        // Send warning notification (if enabled)
        sharedData.recordWarning(event: event.rawValue, activity: activity.rawValue)
    }

    // MARK: - Event Did Reach Threshold

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        // Called when an event reaches its threshold
        // This is when time limits are hit

        print("🚫 Event \(event) reached threshold for \(activity)")

        // Apply shield to block the app
        applyShield(for: activity)

        // Record threshold reached
        sharedData.recordThreshold(event: event.rawValue, activity: activity.rawValue)
    }

    // MARK: - Interval Will Start Warning

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)

        print("⚠️ Interval will start warning for \(activity)")
    }

    // MARK: - Interval Will End Warning

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)

        print("⚠️ Interval will end warning for \(activity)")
    }

    // MARK: - Helper Methods

    private func determineCategory(for activity: DeviceActivityName) -> String {
        // Look up the app category from shared data
        // This data is synced from the main app
        return sharedData.getCategoryForActivity(activity.rawValue) ?? "uncategorized"
    }

    private func updateEducationalProgress() {
        // Calculate total educational time for today
        let sessions = sharedData.getTodaysSessions()
        let educationalSessions = sessions.filter { $0.category == "educational" }

        let totalSeconds = educationalSessions.reduce(0) { sum, session in
            sum + (session.durationSeconds ?? 0)
        }

        let totalMinutes = totalSeconds / 60

        // Get required educational minutes from rules
        let requiredMinutes = sharedData.getRequiredEducationalMinutes()

        // Update progress
        sharedData.updateEducationalProgress(
            currentMinutes: totalMinutes,
            requiredMinutes: requiredMinutes
        )
    }

    private func checkAndUpdateEnforcement() {
        // Check if educational requirement is met
        let progress = sharedData.getEducationalProgress()

        if progress.currentMinutes >= progress.requiredMinutes {
            // Requirement met - unlock recreational apps
            removeShields()
        } else {
            // Requirement not met - keep recreational apps locked
            applyRecreationalShields()
        }
    }

    private func applyShield(for activity: DeviceActivityName) {
        // Apply a shield to block the app
        let store = ManagedSettingsStore()

        // Get the apps to shield from shared data
        let recreationalApps = sharedData.getRecreationalApps()

        // Note: In production, you need to use FamilyActivitySelection
        // with proper application tokens obtained through FamilyActivityPicker

        // For now, this is a placeholder for the shield application logic
        print("🛡️ Applying shield for: \(activity)")
    }

    private func applyRecreationalShields() {
        let store = ManagedSettingsStore()

        // Shield all recreational apps
        let recreationalApps = sharedData.getRecreationalApps()

        print("🔒 Applying shields to \(recreationalApps.count) recreational apps")

        // In production, apply actual shields here
        // store.shield.applications = selectedApplicationTokens
    }

    private func removeShields() {
        let store = ManagedSettingsStore()

        // Remove all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        print("🔓 Removed all shields - recreational apps unlocked")
    }

    // MARK: - Helper Methods

    private func extractBundleId(from activityName: String) -> String {
        // Activity name might be the bundle ID itself or contain it
        // For now, assume it is the bundle ID
        // In production, you would parse this from the DeviceActivityName properly
        return activityName
    }

    private func extractAppName(from activityName: String) -> String {
        // Extract a friendly app name from bundle ID
        // e.g., "com.apple.mobilesafari" -> "Safari"
        let components = activityName.components(separatedBy: ".")
        if let lastComponent = components.last {
            return lastComponent.capitalized
        }
        return activityName
    }
}

// MARK: - Usage Session Data

struct UsageSessionData: Codable {
    let id: UUID
    let activityName: String
    let bundleId: String
    let appName: String
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int?
    var category: AppCategory
    let date: String

    init(activityName: String, bundleId: String, appName: String, startTime: Date, category: String) {
        self.id = UUID()
        self.activityName = activityName
        self.bundleId = bundleId
        self.appName = appName
        self.startTime = startTime
        self.endTime = nil
        self.durationSeconds = nil
        self.category = AppCategory(rawValue: category) ?? .uncategorized

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.date = formatter.string(from: Date())
    }
}

// MARK: - Educational Progress

struct EducationalProgress: Codable {
    var currentMinutes: Int
    var requiredMinutes: Int
    var date: String

    var isRequirementMet: Bool {
        currentMinutes >= requiredMinutes
    }

    var progressPercentage: Double {
        guard requiredMinutes > 0 else { return 1.0 }
        return min(Double(currentMinutes) / Double(requiredMinutes), 1.0)
    }
}
