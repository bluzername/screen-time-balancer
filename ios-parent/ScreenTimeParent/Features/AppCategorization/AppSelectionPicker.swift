// AppSelectionPicker.swift
// Screen Time Parent
//
// FamilyActivityPicker wrapper for selecting apps to categorize

import SwiftUI
import FamilyControls

struct AppSelectionPicker: View {
    @Binding var selection: FamilyActivitySelection
    @State private var isPresented = false
    let title: String
    let category: AppCategory

    var body: some View {
        Button(action: { isPresented = true }) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(categoryColor)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)

                    if selection.applicationTokens.isEmpty {
                        Text("Tap to select apps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(selection.applicationTokens.count) apps selected")
                            .font(.caption)
                            .foregroundColor(categoryColor)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .familyActivityPicker(
            isPresented: $isPresented,
            selection: $selection
        )
    }

    private var categoryColor: Color {
        switch category {
        case .educational:
            return .green
        case .recreational:
            return .purple
        case .utility:
            return .blue
        case .uncategorized:
            return .gray
        }
    }
}

// MARK: - App Selection Manager

@MainActor
class AppSelectionManager: ObservableObject {
    @Published var educationalSelection = FamilyActivitySelection()
    @Published var recreationalSelection = FamilyActivitySelection()

    // Convert selections to storable app data
    func extractAppsFromSelection(_ selection: FamilyActivitySelection, category: AppCategory) -> [ExtractedApp] {
        var apps: [ExtractedApp] = []

        // Note: ApplicationTokens are opaque and can't be directly converted to bundle IDs
        // In a real implementation, you would need to:
        // 1. Use DeviceActivityReport to get app information
        // 2. Or maintain a mapping of selected apps

        // For now, we'll create placeholder apps based on token count
        for (index, token) in selection.applicationTokens.enumerated() {
            apps.append(ExtractedApp(
                token: token,
                displayName: "App \(index + 1)",
                bundleIdentifier: "unknown.\(index)",
                category: category
            ))
        }

        return apps
    }

    func saveSelectionsToBackend(familyId: UUID, appsRepository: AppsRepository) async throws {
        // Educational apps
        let educationalApps = extractAppsFromSelection(educationalSelection, category: .educational)

        // Recreational apps
        let recreationalApps = extractAppsFromSelection(recreationalSelection, category: .recreational)

        // Save to backend (implementation depends on your backend API)
        print("Saving \(educationalApps.count) educational apps")
        print("Saving \(recreationalApps.count) recreational apps")
    }
}

struct ExtractedApp: Identifiable {
    let id = UUID()
    let token: ApplicationToken
    let displayName: String
    let bundleIdentifier: String
    let category: AppCategory
}

// MARK: - Device Activity Report for App Discovery

import DeviceActivity

struct AppUsageReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "App Discovery")

    var body: some View {
        Text("App usage data will appear here")
    }
}
