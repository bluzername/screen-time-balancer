// AppTokenStorage.swift
// Screen Time Child
//
// Secure storage for FamilyActivity ApplicationTokens

import Foundation
import FamilyControls
import ManagedSettings

/// Manages storage and retrieval of ApplicationTokens for app shielding
@MainActor
class AppTokenStorage: ObservableObject {

    // MARK: - Published Selections

    @Published var educationalSelection = FamilyActivitySelection()
    @Published var recreationalSelection = FamilyActivitySelection()

    // MARK: - Keychain Keys

    private enum KeychainKey {
        static let educationalTokens = "com.screentimechild.tokens.educational"
        static let recreationalTokens = "com.screentimechild.tokens.recreational"
    }

    // MARK: - Initialization

    init() {
        loadSelections()
    }

    // MARK: - Save Selections

    func saveEducationalSelection(_ selection: FamilyActivitySelection) {
        educationalSelection = selection
        saveToSharedContainer(selection, key: "educational_selection")
        print("✅ Saved \(selection.applicationTokens.count) educational app tokens")
    }

    func saveRecreationalSelection(_ selection: FamilyActivitySelection) {
        recreationalSelection = selection
        saveToSharedContainer(selection, key: "recreational_selection")
        print("✅ Saved \(selection.applicationTokens.count) recreational app tokens")
    }

    // MARK: - Load Selections

    private func loadSelections() {
        if let educational = loadFromSharedContainer(key: "educational_selection") {
            educationalSelection = educational
            print("📱 Loaded \(educational.applicationTokens.count) educational tokens")
        }

        if let recreational = loadFromSharedContainer(key: "recreational_selection") {
            recreationalSelection = recreational
            print("📱 Loaded \(recreational.applicationTokens.count) recreational tokens")
        }
    }

    // MARK: - Shared Container Persistence

    private let appGroupIdentifier = "group.com.yourcompany.screentimechild"

    private func saveToSharedContainer(_ selection: FamilyActivitySelection, key: String) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Failed to access shared UserDefaults")
            return
        }

        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: selection,
                requiringSecureCoding: true
            )
            sharedDefaults.set(data, forKey: key)
        } catch {
            print("❌ Failed to save selection: \(error)")
        }
    }

    private func loadFromSharedContainer(key: String) -> FamilyActivitySelection? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Failed to access shared UserDefaults")
            return nil
        }

        guard let data = sharedDefaults.data(forKey: key) else {
            return nil
        }

        do {
            guard let selection = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: FamilyActivitySelection.self,
                from: data
            ) else {
                return nil
            }
            return selection
        } catch {
            print("❌ Failed to load selection: \(error)")
            return nil
        }
    }

    // MARK: - Helper Methods

    func getEducationalTokens() -> Set<ApplicationToken> {
        return educationalSelection.applicationTokens
    }

    func getRecreationalTokens() -> Set<ApplicationToken> {
        return recreationalSelection.applicationTokens
    }

    func hasEducationalApps() -> Bool {
        return !educationalSelection.applicationTokens.isEmpty
    }

    func hasRecreationalApps() -> Bool {
        return !recreationalSelection.applicationTokens.isEmpty
    }

    func clearAllSelections() {
        educationalSelection = FamilyActivitySelection()
        recreationalSelection = FamilyActivitySelection()

        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        sharedDefaults.removeObject(forKey: "educational_selection")
        sharedDefaults.removeObject(forKey: "recreational_selection")

        print("🗑️ Cleared all app selections")
    }

    // MARK: - Category Check

    func getCategoryForToken(_ token: ApplicationToken) -> AppCategory? {
        if educationalSelection.applicationTokens.contains(token) {
            return .educational
        }
        if recreationalSelection.applicationTokens.contains(token) {
            return .recreational
        }
        return nil
    }
}

// MARK: - App Selection Setup View

import SwiftUI

struct AppSelectionSetupView: View {
    @StateObject private var tokenStorage = AppTokenStorage()
    @State private var showEducationalPicker = false
    @State private var showRecreationalPicker = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Select which apps are educational and which are for fun. This helps the app track your screen time balance.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("App Selection")
                }

                Section {
                    Button(action: { showEducationalPicker = true }) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.green)

                            VStack(alignment: .leading) {
                                Text("Educational Apps")
                                    .foregroundColor(.primary)

                                if tokenStorage.hasEducationalApps() {
                                    Text("\(tokenStorage.getEducationalTokens().count) apps selected")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Not configured")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .familyActivityPicker(
                        isPresented: $showEducationalPicker,
                        selection: $tokenStorage.educationalSelection
                    )
                    .onChange(of: tokenStorage.educationalSelection) { newValue in
                        tokenStorage.saveEducationalSelection(newValue)
                    }

                    Button(action: { showRecreationalPicker = true }) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(.purple)

                            VStack(alignment: .leading) {
                                Text("Recreational Apps")
                                    .foregroundColor(.primary)

                                if tokenStorage.hasRecreationalApps() {
                                    Text("\(tokenStorage.getRecreationalTokens().count) apps selected")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                } else {
                                    Text("Not configured")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .familyActivityPicker(
                        isPresented: $showRecreationalPicker,
                        selection: $tokenStorage.recreationalSelection
                    )
                    .onChange(of: tokenStorage.recreationalSelection) { newValue in
                        tokenStorage.saveRecreationalSelection(newValue)
                    }
                } header: {
                    Text("Categories")
                }

                if tokenStorage.hasEducationalApps() || tokenStorage.hasRecreationalApps() {
                    Section {
                        Button("Clear All Selections", role: .destructive) {
                            tokenStorage.clearAllSelections()
                        }
                    }
                }
            }
            .navigationTitle("Configure Apps")
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
