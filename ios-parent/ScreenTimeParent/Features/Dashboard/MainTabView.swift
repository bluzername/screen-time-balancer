// MainTabView.swift
// Screen Time Parent - Main tab navigation

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            FamilyManagementView()
                .tabItem {
                    Label("Family", systemImage: "person.3.fill")
                }
                .tag(1)

            RulesManagementView()
                .tabItem {
                    Label("Rules", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(2)

            AppCategorizationView()
                .tabItem {
                    Label("Apps", systemImage: "square.grid.2x2.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        ErrorView(message: error) {
                            viewModel.loadData()
                        }
                    } else {
                        ForEach(viewModel.childStatuses) { status in
                            ChildStatusCard(status: status)
                        }

                        if viewModel.childStatuses.isEmpty {
                            EmptyStateView(
                                icon: "person.3",
                                title: "No Children Added",
                                message: "Add children to your family to start monitoring screen time"
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.loadData() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}

struct ChildStatusCard: View {
    let status: EnforcementStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text(status.childName ?? "Unknown")
                        .font(.headline)
                    Text(status.deviceName ?? "No device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: status.requirementMet ? "checkmark.circle.fill" : "lock.circle.fill")
                    .foregroundColor(status.requirementMet ? .green : .orange)
            }

            ProgressView(value: status.progressPercentage)
                .tint(status.requirementMet ? .green : .orange)

            HStack {
                VStack(alignment: .leading) {
                    Text("Educational Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(status.educationalMinutes) / \(status.requiredEducationalMinutes) min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Recreational Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(status.recreationalMinutesUsed) / \(status.recreationalMinutesAvailable) min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

class DashboardViewModel: ObservableObject {
    @Published var childStatuses: [EnforcementStatus] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let familyRepository = FamilyRepository()
    private let usageRepository = UsageRepository()

    @MainActor
    func loadData() {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                let families = try await familyRepository.getUserFamilies()
                guard let family = families.first else { return }

                let members = try await familyRepository.getFamilyMembers(familyId: family.id)
                let children = members.filter { $0.isChild }

                var statuses: [EnforcementStatus] = []
                for child in children {
                    if let status = try await usageRepository.getEnforcementStatus(childId: child.userId) {
                        statuses.append(status)
                    }
                }

                childStatuses = statuses
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    if let user = authViewModel.currentUser {
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Name", value: user.fullName ?? "Not set")
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Helper Views

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
