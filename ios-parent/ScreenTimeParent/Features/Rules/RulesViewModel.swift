// RulesViewModel.swift
// Screen Time Parent
//
// Rules management business logic

import Foundation
import SwiftUI

@MainActor
class RulesViewModel: ObservableObject {
    @Published var rules: [ScreenTimeRule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingCreateRule = false
    @Published var editingRule: ScreenTimeRule?

    private let rulesRepository: RulesRepositoryProtocol
    private let familyRepository: FamilyRepositoryProtocol
    private var currentFamilyId: UUID?

    init(rulesRepository: RulesRepositoryProtocol = RulesRepository(),
         familyRepository: FamilyRepositoryProtocol = FamilyRepository()) {
        self.rulesRepository = rulesRepository
        self.familyRepository = familyRepository
    }

    // MARK: - Load Rules

    func loadRules() {
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

                // Load rules for family
                rules = try await rulesRepository.getRules(familyId: familyId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Create Rule

    func createRule(
        name: String,
        description: String?,
        childId: UUID?,
        requiredEducationalMinutes: Int,
        maxRecreationalMinutes: Int?,
        startTime: String?,
        endTime: String?,
        activeDays: [Int]
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
                let request = CreateRuleRequest(
                    familyId: familyId,
                    childId: childId,
                    name: name,
                    description: description,
                    requiredEducationalMinutes: requiredEducationalMinutes,
                    maxRecreationalMinutes: maxRecreationalMinutes,
                    startTime: startTime,
                    endTime: endTime,
                    activeDays: activeDays,
                    priority: 0,
                    isActive: true
                )

                let newRule = try await rulesRepository.createRule(request)
                rules.append(newRule)
                rules.sort { $0.priority > $1.priority }

                showingCreateRule = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Update Rule

    func updateRule(
        id: UUID,
        name: String?,
        description: String?,
        requiredEducationalMinutes: Int?,
        maxRecreationalMinutes: Int?,
        startTime: String?,
        endTime: String?,
        activeDays: [Int]?,
        isActive: Bool?
    ) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                let request = UpdateRuleRequest(
                    name: name,
                    description: description,
                    requiredEducationalMinutes: requiredEducationalMinutes,
                    maxRecreationalMinutes: maxRecreationalMinutes,
                    startTime: startTime,
                    endTime: endTime,
                    activeDays: activeDays,
                    priority: nil,
                    isActive: isActive
                )

                let updatedRule = try await rulesRepository.updateRule(id: id, request)

                // Update in array
                if let index = rules.firstIndex(where: { $0.id == id }) {
                    rules[index] = updatedRule
                }

                editingRule = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Delete Rule

    func deleteRule(_ rule: ScreenTimeRule) {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                try await rulesRepository.deleteRule(id: rule.id)
                rules.removeAll { $0.id == rule.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Toggle Rule

    func toggleRule(_ rule: ScreenTimeRule) {
        Task {
            let request = UpdateRuleRequest(
                name: nil,
                description: nil,
                requiredEducationalMinutes: nil,
                maxRecreationalMinutes: nil,
                startTime: nil,
                endTime: nil,
                activeDays: nil,
                priority: nil,
                isActive: !rule.isActive
            )

            _ = try? await rulesRepository.updateRule(id: rule.id, request)

            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                rules[index].isActive.toggle()
            }
        }
    }

    // MARK: - Helpers

    func getFamilyChildren() async -> [FamilyMember] {
        guard let familyId = currentFamilyId else { return [] }

        do {
            let members = try await familyRepository.getFamilyMembers(familyId: familyId)
            return members.filter { $0.isChild }
        } catch {
            return []
        }
    }
}
