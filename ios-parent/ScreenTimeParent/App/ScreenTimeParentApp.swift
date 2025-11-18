// ScreenTimeParentApp.swift
// Screen Time Parent
//
// Main app entry point

import SwiftUI

@main
struct ScreenTimeParentApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Validate configuration on startup
        if !Config.validateConfiguration() {
            print("⚠️ App configuration is invalid. Please update Config.swift with your Supabase credentials.")
        }

        // Setup appearance
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.colorScheme)
        }
    }

    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var authViewModel = AuthenticationViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                AuthenticationView(viewModel: authViewModel)
            }
        }
        .onAppear {
            authViewModel.checkAuthStatus()
        }
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
                    .foregroundColor(.blue)

                Text("Screen Time Balancer")
                    .font(.title)
                    .fontWeight(.semibold)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var colorScheme: ColorScheme?

    // Global app state
    @Published var isOnline = true
    @Published var lastSyncTime: Date?

    init() {
        // Load saved preferences
        loadPreferences()

        // Monitor network connectivity
        startNetworkMonitoring()
    }

    private func loadPreferences() {
        // Load color scheme preference
        if let colorSchemeRaw = UserDefaults.standard.string(forKey: "colorScheme") {
            switch colorSchemeRaw {
            case "light":
                colorScheme = .light
            case "dark":
                colorScheme = .dark
            default:
                colorScheme = nil // System default
            }
        }
    }

    private func startNetworkMonitoring() {
        // TODO: Implement network monitoring using NWPathMonitor
        // For now, assume online
        isOnline = true
    }

    func saveColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
        let value = scheme == .light ? "light" : scheme == .dark ? "dark" : "system"
        UserDefaults.standard.set(value, forKey: "colorScheme")
    }
}
