// ScreenTimeChildApp.swift
// Screen Time Child
//
// Main app entry point for child device

import SwiftUI
import FamilyControls
import BackgroundTasks

@main
struct ScreenTimeChildApp: App {
    @StateObject private var appState = ChildAppState()
    @StateObject private var enforcementEngine = EnforcementEngineV2()
    @State private var backgroundSyncManager = BackgroundSyncManager()

    init() {
        if !Config.validateConfiguration() {
            print("⚠️ App configuration is invalid")
        }

        // Register background tasks
        registerBackgroundTasks()

        // Request Screen Time API authorization
        Task {
            await requestScreenTimeAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(enforcementEngine)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    scheduleBackgroundSync()
                }
        }
    }

    private func requestScreenTimeAuthorization() async {
        let center = AuthorizationCenter.shared
        do {
            try await center.requestAuthorization(for: .individual)
            print("✅ Screen Time authorization granted")
        } catch {
            print("❌ Screen Time authorization failed: \(error)")
        }
    }

    // MARK: - Background Task Registration

    private func registerBackgroundTasks() {
        // Register background refresh task for syncing
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.screentimechild.sync",
            using: nil
        ) { task in
            self.handleBackgroundSync(task: task as! BGAppRefreshTask)
        }

        // Schedule initial sync
        scheduleBackgroundSync()
    }

    private func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.screentimechild.sync")

        // Run task every 15 minutes at minimum
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("⏰ Background sync scheduled")
        } catch {
            print("❌ Could not schedule background sync: \(error)")
        }
    }

    private func handleBackgroundSync(task: BGAppRefreshTask) {
        // Create a new task to handle the sync
        Task {
            do {
                await backgroundSyncManager.syncPendingSessions()
                task.setTaskCompleted(success: true)
            } catch {
                print("❌ Background sync failed: \(error)")
                task.setTaskCompleted(success: false)
            }

            // Schedule next sync
            scheduleBackgroundSync()
        }

        // Set expiration handler
        task.expirationHandler = {
            print("⏱️ Background task expired")
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appState: ChildAppState
    @StateObject private var authViewModel = ChildAuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                ChildDashboardView()
                    .environmentObject(authViewModel)
            } else {
                ChildAuthenticationView(viewModel: authViewModel)
            }
        }
        .onAppear {
            authViewModel.checkAuthStatus()
        }
    }
}

// MARK: - Child App State

class ChildAppState: ObservableObject {
    @Published var isOnline = true
    @Published var lastSyncTime: Date?
    @Published var currentFamily: Family?
    @Published var currentDevice: Device?

    init() {
        loadDeviceInfo()
    }

    private func loadDeviceInfo() {
        // Load cached device info from UserDefaults
        if let deviceData = UserDefaults.standard.data(forKey: "cached_device"),
           let device = try? JSONDecoder().decode(Device.self, from: deviceData) {
            currentDevice = device
        }
    }

    func saveDeviceInfo(_ device: Device) {
        if let encoded = try? JSONEncoder().encode(device) {
            UserDefaults.standard.set(encoded, forKey: "cached_device")
        }
        currentDevice = device
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "hourglass")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Screen Time Balancer")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Child")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProgressView()
            }
        }
    }
}
