// RulesManagementView.swift
// Screen Time Parent
//
// Screen time rules management UI

import SwiftUI

struct RulesManagementView: View {
    @StateObject private var viewModel = RulesViewModel()
    @State private var showingTemplates = false

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.rules.isEmpty {
                    ProgressView()
                } else if let error = viewModel.errorMessage, viewModel.rules.isEmpty {
                    ErrorView(message: error) {
                        viewModel.loadRules()
                    }
                } else if viewModel.rules.isEmpty {
                    EmptyRulesView(viewModel: viewModel)
                } else {
                    RulesListView(viewModel: viewModel)
                }
            }
            .navigationTitle("Screen Time Rules")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.showingCreateRule = true }) {
                            Label("Create Custom Rule", systemImage: "slider.horizontal.3")
                        }

                        Button(action: { showingTemplates = true }) {
                            Label("Use Template", systemImage: "doc.text")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateRule) {
                CreateRuleSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingTemplates) {
                RuleTemplatesSheet(viewModel: viewModel)
            }
            .sheet(item: $viewModel.editingRule) { rule in
                EditRuleSheet(rule: rule, viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadRules()
            }
        }
    }
}

// MARK: - Rules List View

struct RulesListView: View {
    @ObservedObject var viewModel: RulesViewModel

    var body: some View {
        List {
            ForEach(viewModel.rules) { rule in
                RuleRow(rule: rule, viewModel: viewModel)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteRule(rule)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            viewModel.editingRule = rule
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.loadRules()
        }
    }
}

// MARK: - Rule Row

struct RuleRow: View {
    let rule: ScreenTimeRule
    @ObservedObject var viewModel: RulesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name)
                        .font(.headline)

                    if let description = rule.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { rule.isActive },
                    set: { _ in viewModel.toggleRule(rule) }
                ))
                .labelsHidden()
            }

            Divider()

            // Rule details
            VStack(spacing: 8) {
                RuleDetailRow(
                    icon: "book.fill",
                    label: "Educational Time",
                    value: rule.educationalTimeFormatted,
                    color: .green
                )

                if let recreational = rule.recreationalTimeFormatted {
                    RuleDetailRow(
                        icon: "gamecontroller.fill",
                        label: "Recreational Limit",
                        value: recreational,
                        color: .blue
                    )
                }

                RuleDetailRow(
                    icon: "clock.fill",
                    label: "Time Window",
                    value: rule.timeWindowFormatted,
                    color: .orange
                )

                RuleDetailRow(
                    icon: "calendar",
                    label: "Active Days",
                    value: rule.activeDaysFormatted,
                    color: .purple
                )
            }

            // Applies to
            if rule.appliesToAllChildren {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                    Text("Applies to all children")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .opacity(rule.isActive ? 1.0 : 0.5)
    }
}

struct RuleDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Empty Rules View

struct EmptyRulesView: View {
    @ObservedObject var viewModel: RulesViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Rules Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create rules to manage screen time for your children")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button(action: { viewModel.showingCreateRule = true }) {
                    Label("Create Custom Rule", systemImage: "slider.horizontal.3")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: { }) {
                    Label("Use Template", systemImage: "doc.text")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
    }
}

// MARK: - Create Rule Sheet

struct CreateRuleSheet: View {
    @ObservedObject var viewModel: RulesViewModel
    @Environment(\.dismiss) var dismiss

    @State private var ruleName = ""
    @State private var ruleDescription = ""
    @State private var selectedChild: FamilyMember?
    @State private var requiredEducationalMinutes = 30
    @State private var maxRecreationalMinutes = 120
    @State private var hasRecreationalLimit = true
    @State private var hasTimeWindow = false
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6]

    @State private var children: [FamilyMember] = []

    var body: some View {
        NavigationView {
            Form {
                // Basic Info
                Section("Rule Information") {
                    TextField("Rule Name", text: $ruleName)
                    TextField("Description (Optional)", text: $ruleDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Apply To
                Section("Apply To") {
                    Picker("Child", selection: $selectedChild) {
                        Text("All Children").tag(nil as FamilyMember?)
                        ForEach(children) { child in
                            Text(child.displayName).tag(child as FamilyMember?)
                        }
                    }
                }

                // Time Requirements
                Section("Educational Time Required") {
                    Stepper("\(requiredEducationalMinutes) minutes", value: $requiredEducationalMinutes, in: 0...240, step: 5)
                }

                Section {
                    Toggle("Set Recreational Limit", isOn: $hasRecreationalLimit)

                    if hasRecreationalLimit {
                        Stepper("\(maxRecreationalMinutes) minutes", value: $maxRecreationalMinutes, in: 0...480, step: 15)
                    }
                } header: {
                    Text("Recreational Time Limit")
                } footer: {
                    Text("Maximum time allowed for games and entertainment apps")
                }

                // Time Window
                Section {
                    Toggle("Set Time Window", isOn: $hasTimeWindow)

                    if hasTimeWindow {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Active Time Window")
                } footer: {
                    Text("Rule only applies during this time window")
                }

                // Active Days
                Section("Active Days") {
                    ForEach(0..<7) { day in
                        Toggle(dayName(day), isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Create Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createRule()
                    }
                    .disabled(!isValid)
                }
            }
            .task {
                children = await viewModel.getFamilyChildren()
            }
        }
    }

    private var isValid: Bool {
        !ruleName.isEmpty && !selectedDays.isEmpty
    }

    private func createRule() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        viewModel.createRule(
            name: ruleName,
            description: ruleDescription.isEmpty ? nil : ruleDescription,
            childId: selectedChild?.userId,
            requiredEducationalMinutes: requiredEducationalMinutes,
            maxRecreationalMinutes: hasRecreationalLimit ? maxRecreationalMinutes : nil,
            startTime: hasTimeWindow ? formatter.string(from: startTime) : nil,
            endTime: hasTimeWindow ? formatter.string(from: endTime) : nil,
            activeDays: Array(selectedDays).sorted()
        )
    }

    private func dayName(_ day: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[day]
    }
}

// MARK: - Edit Rule Sheet

struct EditRuleSheet: View {
    let rule: ScreenTimeRule
    @ObservedObject var viewModel: RulesViewModel
    @Environment(\.dismiss) var dismiss

    @State private var ruleName: String
    @State private var ruleDescription: String
    @State private var requiredEducationalMinutes: Int
    @State private var maxRecreationalMinutes: Int
    @State private var hasRecreationalLimit: Bool
    @State private var isActive: Bool

    init(rule: ScreenTimeRule, viewModel: RulesViewModel) {
        self.rule = rule
        self.viewModel = viewModel
        _ruleName = State(initialValue: rule.name)
        _ruleDescription = State(initialValue: rule.description ?? "")
        _requiredEducationalMinutes = State(initialValue: rule.requiredEducationalMinutes)
        _maxRecreationalMinutes = State(initialValue: rule.maxRecreationalMinutes ?? 120)
        _hasRecreationalLimit = State(initialValue: rule.maxRecreationalMinutes != nil)
        _isActive = State(initialValue: rule.isActive)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Rule Information") {
                    TextField("Rule Name", text: $ruleName)
                    TextField("Description", text: $ruleDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Status") {
                    Toggle("Active", isOn: $isActive)
                }

                Section("Educational Time Required") {
                    Stepper("\(requiredEducationalMinutes) minutes", value: $requiredEducationalMinutes, in: 0...240, step: 5)
                }

                Section {
                    Toggle("Set Limit", isOn: $hasRecreationalLimit)

                    if hasRecreationalLimit {
                        Stepper("\(maxRecreationalMinutes) minutes", value: $maxRecreationalMinutes, in: 0...480, step: 15)
                    }
                } header: {
                    Text("Recreational Time Limit")
                }
            }
            .navigationTitle("Edit Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(ruleName.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        viewModel.updateRule(
            id: rule.id,
            name: ruleName,
            description: ruleDescription.isEmpty ? nil : ruleDescription,
            requiredEducationalMinutes: requiredEducationalMinutes,
            maxRecreationalMinutes: hasRecreationalLimit ? maxRecreationalMinutes : nil,
            startTime: nil,
            endTime: nil,
            activeDays: nil,
            isActive: isActive
        )
    }
}

// MARK: - Rule Templates Sheet

struct RuleTemplatesSheet: View {
    @ObservedObject var viewModel: RulesViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(RuleTemplate.templates, id: \.name) { template in
                    Button(action: {
                        applyTemplate(template)
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.name)
                                .font(.headline)

                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 16) {
                                Label("\(template.requiredEducationalMinutes)m edu", systemImage: "book.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)

                                Label("\(template.maxRecreationalMinutes)m rec", systemImage: "gamecontroller.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)

                                Label("\(template.activeDays.count) days", systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Rule Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func applyTemplate(_ template: RuleTemplate) {
        viewModel.createRule(
            name: template.name,
            description: template.description,
            childId: nil,
            requiredEducationalMinutes: template.requiredEducationalMinutes,
            maxRecreationalMinutes: template.maxRecreationalMinutes,
            startTime: template.startTime,
            endTime: template.endTime,
            activeDays: template.activeDays
        )
        dismiss()
    }
}

// MARK: - Preview

struct RulesManagementView_Previews: PreviewProvider {
    static var previews: some View {
        RulesManagementView()
    }
}
