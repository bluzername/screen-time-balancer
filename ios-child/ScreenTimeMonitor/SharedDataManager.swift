// SharedDataManager.swift
// Shared between main app and Device Activity Monitor extension
//
// Manages data sharing via App Groups

import Foundation

class SharedDataManager {

    // MARK: - App Group Configuration

    // TODO: Replace with your actual App Group identifier
    // Format: group.com.yourcompany.screentimechild
    private let appGroupIdentifier = "group.com.yourcompany.screentimechild"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    // MARK: - Keys

    private enum Keys {
        static let activeSessions = "activeSessions"
        static let completedSessions = "completedSessions"
        static let appCategories = "appCategories"
        static let requiredEducationalMinutes = "requiredEducationalMinutes"
        static let educationalProgress = "educationalProgress"
        static let recreationalApps = "recreationalApps"
        static let lastSync = "lastSync"
    }

    // MARK: - Session Management

    func saveSessionStart(_ session: UsageSessionData) {
        var sessions = getActiveSessions()
        sessions.append(session)
        saveActiveSessions(sessions)
    }

    func getActiveSession(for activityName: String) -> UsageSessionData? {
        let sessions = getActiveSessions()
        return sessions.first { $0.activityName == activityName }
    }

    func saveCompletedSession(_ session: UsageSessionData) {
        // Remove from active sessions
        var activeSessions = getActiveSessions()
        activeSessions.removeAll { $0.id == session.id }
        saveActiveSessions(activeSessions)

        // Add to completed sessions
        var completedSessions = getCompletedSessions()
        completedSessions.append(session)
        saveCompletedSessions(completedSessions)

        // Mark for sync
        markForSync()
    }

    func getTodaysSessions() -> [UsageSessionData] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        let sessions = getCompletedSessions()
        return sessions.filter { $0.date == today }
    }

    private func getActiveSessions() -> [UsageSessionData] {
        guard let data = sharedDefaults?.data(forKey: Keys.activeSessions),
              let sessions = try? JSONDecoder().decode([UsageSessionData].self, from: data) else {
            return []
        }
        return sessions
    }

    private func saveActiveSessions(_ sessions: [UsageSessionData]) {
        if let data = try? JSONEncoder().encode(sessions) {
            sharedDefaults?.set(data, forKey: Keys.activeSessions)
        }
    }

    private func getCompletedSessions() -> [UsageSessionData] {
        guard let data = sharedDefaults?.data(forKey: Keys.completedSessions),
              let sessions = try? JSONDecoder().decode([UsageSessionData].self, from: data) else {
            return []
        }
        return sessions
    }

    private func saveCompletedSessions(_ sessions: [UsageSessionData]) {
        if let data = try? JSONEncoder().encode(sessions) {
            sharedDefaults?.set(data, forKey: Keys.completedSessions)
        }
    }

    // MARK: - App Categories

    func getCategoryForActivity(_ activityName: String) -> String? {
        let categories = getAppCategories()
        return categories[activityName]
    }

    func saveAppCategories(_ categories: [String: String]) {
        if let data = try? JSONEncoder().encode(categories) {
            sharedDefaults?.set(data, forKey: Keys.appCategories)
        }
    }

    private func getAppCategories() -> [String: String] {
        guard let data = sharedDefaults?.data(forKey: Keys.appCategories),
              let categories = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return categories
    }

    // MARK: - Rules

    func getRequiredEducationalMinutes() -> Int {
        return sharedDefaults?.integer(forKey: Keys.requiredEducationalMinutes) ?? 30
    }

    func saveRequiredEducationalMinutes(_ minutes: Int) {
        sharedDefaults?.set(minutes, forKey: Keys.requiredEducationalMinutes)
    }

    // MARK: - Educational Progress

    func getEducationalProgress() -> EducationalProgress {
        guard let data = sharedDefaults?.data(forKey: Keys.educationalProgress),
              let progress = try? JSONDecoder().decode(EducationalProgress.self, from: data) else {
            return EducationalProgress(
                currentMinutes: 0,
                requiredMinutes: getRequiredEducationalMinutes(),
                date: todayString()
            )
        }

        // Check if progress is from today
        if progress.date != todayString() {
            // Reset for new day
            return EducationalProgress(
                currentMinutes: 0,
                requiredMinutes: getRequiredEducationalMinutes(),
                date: todayString()
            )
        }

        return progress
    }

    func updateEducationalProgress(currentMinutes: Int, requiredMinutes: Int) {
        let progress = EducationalProgress(
            currentMinutes: currentMinutes,
            requiredMinutes: requiredMinutes,
            date: todayString()
        )

        if let data = try? JSONEncoder().encode(progress) {
            sharedDefaults?.set(data, forKey: Keys.educationalProgress)
        }

        // Notify main app of progress update
        NotificationCenter.default.post(name: .educationalProgressUpdated, object: progress)
    }

    // MARK: - Recreational Apps

    func getRecreationalApps() -> [String] {
        return sharedDefaults?.stringArray(forKey: Keys.recreationalApps) ?? []
    }

    func saveRecreationalApps(_ apps: [String]) {
        sharedDefaults?.set(apps, forKey: Keys.recreationalApps)
    }

    // MARK: - Warnings and Thresholds

    func recordWarning(event: String, activity: String) {
        print("⚠️ Warning recorded: \(event) for \(activity)")
        // Could send local notification here
    }

    func recordThreshold(event: String, activity: String) {
        print("🚫 Threshold reached: \(event) for \(activity)")
        // Could send local notification here
    }

    // MARK: - Sync Management

    func markForSync() {
        sharedDefaults?.set(Date(), forKey: Keys.lastSync)
    }

    func getLastSyncDate() -> Date? {
        return sharedDefaults?.object(forKey: Keys.lastSync) as? Date
    }

    func clearCompletedSessions() {
        // Called after successful sync to backend
        sharedDefaults?.removeObject(forKey: Keys.completedSessions)
    }

    // MARK: - Cleanup

    func cleanupOldSessions() {
        // Remove sessions older than 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoffDate = formatter.string(from: sevenDaysAgo)

        var sessions = getCompletedSessions()
        sessions.removeAll { $0.date < cutoffDate }
        saveCompletedSessions(sessions)
    }

    // MARK: - Helpers

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let educationalProgressUpdated = Notification.Name("educationalProgressUpdated")
    static let sessionsReadyForSync = Notification.Name("sessionsReadyForSync")
}
