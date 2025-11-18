// ScreenTimeChildApp.swift
// Screen Time Child
//
// Main app entry point for child device

import SwiftUI
import FamilyControls

@main
struct ScreenTimeChildApp: App {
    @StateObject private var appState = ChildAppState()
    @StateObject private var enforcementEngine = EnforcementEngine()

    init() {
        if !Config.validateConfiguration() {
            print("⚠️ App configuration is invalid")
        }

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
