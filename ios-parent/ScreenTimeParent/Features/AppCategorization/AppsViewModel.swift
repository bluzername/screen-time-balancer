// AppsViewModel.swift
// Screen Time Parent
//
// App categorization business logic

import Foundation
import SwiftUI

@MainActor
class AppsViewModel: ObservableObject {
    @Published var apps: [App] = []
    @Published var filteredApps: [App] = []
    @Published var selectedCategory: AppCategory?
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddApp = false
    @Published var editingApp: App?

    private let appsRepository: AppsRepositoryProtocol
    private let familyRepository: FamilyRepositoryProtocol
    private var currentFamilyId: UUID?

    init(appsRepository: AppsRepositoryProtocol = AppsRepository(),
         familyRepository: FamilyRepositoryProtocol = FamilyRepository()) {
        self.appsRepository = appsRepository
        self.familyRepository = familyRepository
    }

    // MARK: - Load Apps

    func loadApps() {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                // Get user's families
                let families = try await familyRepository.getUserFamilies()
                guard let familyId = families.first?.id else {
                    errorMessage = "No family found. Please create a family first."
                    return
                }

                currentFamilyId = familyId

                // Load apps for family
                apps = try await appsRepository.getApps(familyId: familyId)
                filterApps()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Filtering

    func filterApps() {
        var filtered = apps

        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.appName.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleId.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredApps = filtered
    }

    // MARK: - Create App

    func addApp(
        bundleId: String,
        appName: String,
        category: AppCategory,
        isBlocked: Bool = false,
        timeLimitMinutes: Int? = nil
    ) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            guard let familyId = currentFamilyId else {
                errorMessage = "No family selected"
                return
            }

            do {
                let request = CreateAppRequest(
                    familyId: familyId,
                    bundleId: bundleId,
                    appName: appName,
                    category: category,
                    iconUrl: nil,
                    isBlocked: isBlocked,
                    timeLimitMinutes: timeLimitMinutes,
                    notes: nil
                )

                let newApp = try await appsRepository.createApp(request)
                apps.append(newApp)
                filterApps()

                showingAddApp = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Update App

    func updateApp(
        _ app: App,
        category: AppCategory? = nil,
        isBlocked: Bool? = nil,
        timeLimitMinutes: Int? = nil
    ) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                let request = UpdateAppRequest(
                    category: category,
                    isBlocked: isBlocked,
                    timeLimitMinutes: timeLimitMinutes,
                    notes: nil
                )

                let updatedApp = try await appsRepository.updateApp(id: app.id, request)

                // Update in array
                if let index = apps.firstIndex(where: { $0.id == app.id }) {
                    apps[index] = updatedApp
                    filterApps()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Quick Category Change

    func changeCategory(_ app: App, to category: AppCategory) {
        updateApp(app, category: category)
    }

    // MARK: - Delete App

    func deleteApp(_ app: App) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                try await appsRepository.deleteApp(id: app.id)
                apps.removeAll { $0.id == app.id }
                filterApps()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Bulk Operations

    func bulkCategorize(apps: [App], category: AppCategory) {
        Task {
            for app in apps {
                updateApp(app, category: category)
            }
        }
    }

    // MARK: - Statistics

    var categoryStats: [(category: AppCategory, count: Int)] {
        AppCategory.allCases.map { category in
            let count = apps.filter { $0.category == category }.count
            return (category, count)
        }
    }

    var uncategorizedCount: Int {
        apps.filter { $0.category == .uncategorized }.count
    }
}
