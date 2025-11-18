// AppCategorizationView.swift
// Screen Time Parent
//
// App categorization and management UI

import SwiftUI

struct AppCategorizationView: View {
    @StateObject private var viewModel = AppsViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.apps.isEmpty {
                    ProgressView()
                } else if let error = viewModel.errorMessage, viewModel.apps.isEmpty {
                    ErrorView(message: error) {
                        viewModel.loadApps()
                    }
                } else if viewModel.apps.isEmpty {
                    EmptyAppsView(viewModel: viewModel)
                } else {
                    AppsListView(viewModel: viewModel)
                }
            }
            .navigationTitle("Apps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingAddApp = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search apps")
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.filterApps()
            }
            .sheet(isPresented: $viewModel.showingAddApp) {
                AddAppSheet(viewModel: viewModel)
            }
            .sheet(item: $viewModel.editingApp) { app in
                EditAppSheet(app: app, viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadApps()
            }
        }
    }
}

// MARK: - Apps List View

struct AppsListView: View {
    @ObservedObject var viewModel: AppsViewModel

    var body: some View {
        List {
            // Stats section
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterChip(
                            category: nil,
                            count: viewModel.apps.count,
                            isSelected: viewModel.selectedCategory == nil,
                            viewModel: viewModel
                        )

                        ForEach(AppCategory.allCases, id: \.self) { category in
                            let count = viewModel.apps.filter { $0.category == category }.count
                            CategoryFilterChip(
                                category: category,
                                count: count,
                                isSelected: viewModel.selectedCategory == category,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Apps list
            Section {
                ForEach(viewModel.filteredApps) { app in
                    AppRow(app: app, viewModel: viewModel)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteApp(app)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                viewModel.editingApp = app
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading) {
                            // Quick category buttons
                            ForEach([AppCategory.educational, .recreational, .utility], id: \.self) { category in
                                if app.category != category {
                                    Button {
                                        viewModel.changeCategory(app, to: category)
                                    } label: {
                                        Label(category.displayName, systemImage: category.icon)
                                    }
                                    .tint(categoryColor(category))
                                }
                            }
                        }
                }
            }

            if viewModel.filteredApps.isEmpty && !viewModel.searchText.isEmpty {
                Section {
                    Text("No apps found matching '\(viewModel.searchText)'")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.loadApps()
        }
    }

    private func categoryColor(_ category: AppCategory) -> Color {
        switch category {
        case .educational: return .green
        case .recreational: return .blue
        case .utility: return .gray
        case .uncategorized: return .orange
        }
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let category: AppCategory?
    let count: Int
    let isSelected: Bool
    @ObservedObject var viewModel: AppsViewModel

    var body: some View {
        Button(action: {
            viewModel.selectedCategory = isSelected ? nil : category
            viewModel.filterApps()
        }) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                }

                Text(category?.displayName ?? "All")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? chipColor : Color(.secondarySystemFill))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }

    private var chipColor: Color {
        guard let category = category else { return .blue }
        switch category {
        case .educational: return .green
        case .recreational: return .blue
        case .utility: return .gray
        case .uncategorized: return .orange
        }
    }
}

// MARK: - App Row

struct AppRow: View {
    let app: App
    @ObservedObject var viewModel: AppsViewModel

    var body: some View {
        HStack(spacing: 12) {
            // App icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: app.category.icon)
                    .foregroundColor(categoryColor)
            }

            // App info
            VStack(alignment: .leading, spacing: 4) {
                Text(app.appName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(app.category.displayName, systemImage: app.category.icon)
                        .font(.caption)
                        .foregroundColor(categoryColor)

                    if app.isBlocked {
                        Text("•")
                            .foregroundColor(.secondary)
                        Label("Blocked", systemImage: "hand.raised.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if let timeLimit = app.timeLimitFormatted {
                        Text("•")
                            .foregroundColor(.secondary)
                        Label(timeLimit, systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text(app.bundleId)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.editingApp = app
        }
    }

    private var categoryColor: Color {
        switch app.category {
        case .educational: return .green
        case .recreational: return .blue
        case .utility: return .gray
        case .uncategorized: return .orange
        }
    }
}

// MARK: - Empty Apps View

struct EmptyAppsView: View {
    @ObservedObject var viewModel: AppsViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Apps Added")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Add apps to categorize them as educational or recreational")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: { viewModel.showingAddApp = true }) {
                Label("Add App", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

// MARK: - Add App Sheet

struct AddAppSheet: View {
    @ObservedObject var viewModel: AppsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var bundleId = ""
    @State private var appName = ""
    @State private var selectedCategory: AppCategory = .uncategorized
    @State private var isBlocked = false
    @State private var hasTimeLimit = false
    @State private var timeLimitMinutes = 60

    var body: some View {
        NavigationView {
            Form {
                Section("App Information") {
                    TextField("App Name", text: $appName)
                    TextField("Bundle ID (e.g., com.example.app)", text: $bundleId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(AppCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(selectedCategory.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Toggle("Block App", isOn: $isBlocked)

                    Toggle("Set Time Limit", isOn: $hasTimeLimit)

                    if hasTimeLimit {
                        Stepper("\(timeLimitMinutes) minutes per day", value: $timeLimitMinutes, in: 5...480, step: 5)
                    }
                } header: {
                    Text("Restrictions")
                } footer: {
                    Text("Blocked apps cannot be opened. Time limits restrict daily usage.")
                }
            }
            .navigationTitle("Add App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addApp(
                            bundleId: bundleId,
                            appName: appName,
                            category: selectedCategory,
                            isBlocked: isBlocked,
                            timeLimitMinutes: hasTimeLimit ? timeLimitMinutes : nil
                        )
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !appName.isEmpty && !bundleId.isEmpty
    }
}

// MARK: - Edit App Sheet

struct EditAppSheet: View {
    let app: App
    @ObservedObject var viewModel: AppsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: AppCategory
    @State private var isBlocked: Bool
    @State private var hasTimeLimit: Bool
    @State private var timeLimitMinutes: Int

    init(app: App, viewModel: AppsViewModel) {
        self.app = app
        self.viewModel = viewModel
        _selectedCategory = State(initialValue: app.category)
        _isBlocked = State(initialValue: app.isBlocked)
        _hasTimeLimit = State(initialValue: app.timeLimitMinutes != nil)
        _timeLimitMinutes = State(initialValue: app.timeLimitMinutes ?? 60)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("App Information") {
                    LabeledContent("Name", value: app.appName)
                    LabeledContent("Bundle ID", value: app.bundleId)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(AppCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(selectedCategory.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Toggle("Block App", isOn: $isBlocked)

                    Toggle("Time Limit", isOn: $hasTimeLimit)

                    if hasTimeLimit {
                        Stepper("\(timeLimitMinutes) minutes per day", value: $timeLimitMinutes, in: 5...480, step: 5)
                    }
                } header: {
                    Text("Restrictions")
                }
            }
            .navigationTitle("Edit App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        viewModel.updateApp(
            app,
            category: selectedCategory,
            isBlocked: isBlocked,
            timeLimitMinutes: hasTimeLimit ? timeLimitMinutes : nil
        )
        dismiss()
    }
}

// MARK: - Preview

struct AppCategorizationView_Previews: PreviewProvider {
    static var previews: some View {
        AppCategorizationView()
    }
}
