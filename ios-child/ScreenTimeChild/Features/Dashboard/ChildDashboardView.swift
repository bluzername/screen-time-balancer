// ChildDashboardView.swift
// Screen Time Child
//
// Main dashboard for child showing progress and earned time

import SwiftUI

struct ChildDashboardView: View {
    @EnvironmentObject var enforcementEngine: EnforcementEngine
    @EnvironmentObject var authViewModel: ChildAuthViewModel
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome section
                    WelcomeCard(userName: authViewModel.currentUser?.fullName ?? "There")

                    // Progress card
                    if let earned = enforcementEngine.earnedTime,
                       let rule = enforcementEngine.currentRule {
                        ProgressCard(earnedTime: earned, rule: rule)
                    } else {
                        LoadingCard()
                    }

                    // Status card
                    StatusCard(isRecreationalAllowed: enforcementEngine.isRecreationalAllowed)

                    // Today's usage
                    if let earned = enforcementEngine.earnedTime {
                        UsageBreakdownCard(earnedTime: earned)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("My Screen Time")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                ChildSettingsView()
                    .environmentObject(authViewModel)
            }
            .refreshable {
                await enforcementEngine.syncWithBackend()
            }
        }
    }
}

// MARK: - Welcome Card

struct WelcomeCard: View {
    let userName: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(userName)!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Date(), style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "sun.max.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

// MARK: - Progress Card

struct ProgressCard: View {
    let earnedTime: EarnedTime
    let rule: ScreenTimeRule

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Educational Progress")
                .font(.headline)

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(earnedTime.educationalMinutes) min")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    Spacer()

                    Text("Goal: \(rule.requiredEducationalMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: earnedTime.progressPercentage)
                    .tint(.green)
                    .frame(height: 8)

                if earnedTime.requirementMet {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Goal reached! Great job!")
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                } else {
                    Text("\(earnedTime.remainingEducationalMinutes) minutes remaining")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let isRecreationalAllowed: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isRecreationalAllowed ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(isRecreationalAllowed ? .green : .orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(isRecreationalAllowed ? "Recreational Apps Unlocked" : "Recreational Apps Locked")
                    .font(.headline)

                Text(isRecreationalAllowed ?
                     "You can now use games and entertainment apps!" :
                     "Complete educational time to unlock fun apps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            isRecreationalAllowed ?
            Color.green.opacity(0.1) :
            Color.orange.opacity(0.1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Usage Breakdown Card

struct UsageBreakdownCard: View {
    let earnedTime: EarnedTime

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Usage")
                .font(.headline)

            HStack(spacing: 20) {
                UsageColumn(
                    icon: "book.fill",
                    color: .green,
                    title: "Educational",
                    value: "\(earnedTime.educationalMinutes) min"
                )

                Divider()

                UsageColumn(
                    icon: "gamecontroller.fill",
                    color: .blue,
                    title: "Recreational",
                    value: "\(earnedTime.recreationalMinutesUsed) min"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct UsageColumn: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading Card

struct LoadingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading your progress...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Child Settings View

struct ChildSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: ChildAuthViewModel

    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    if let user = authViewModel.currentUser {
                        LabeledContent("Name", value: user.fullName ?? "Not set")
                        LabeledContent("Email", value: user.email)
                    }
                }

                Section("App") {
                    LabeledContent("Version", value: Config.appVersion)
                    LabeledContent("Build", value: Config.buildNumber)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Child Auth ViewModel

@MainActor
class ChildAuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var currentUser: UserProfile?
    @Published var errorMessage: String?

    private let authRepository = AuthRepository()

    func checkAuthStatus() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let user = try await authRepository.getCurrentUser()
                currentUser = user
                isAuthenticated = user.role == .child
            } catch {
                isAuthenticated = false
            }
        }
    }

    func signIn(email: String, password: String) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                let user = try await authRepository.signIn(email: email, password: password)
                guard user.role == .child else {
                    errorMessage = "This is a child account app. Please use the parent app."
                    return
                }
                currentUser = user
                isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() {
        Task {
            try? await authRepository.signOut()
            isAuthenticated = false
            currentUser = nil
        }
    }
}
