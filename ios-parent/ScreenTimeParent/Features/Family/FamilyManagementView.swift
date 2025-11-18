// FamilyManagementView.swift
// Screen Time Parent
//
// Complete family management UI

import SwiftUI

struct FamilyManagementView: View {
    @StateObject private var viewModel = FamilyViewModel()
    @State private var showingMemberDetails: FamilyMember?

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.families.isEmpty {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        viewModel.loadFamilies()
                    }
                } else if viewModel.families.isEmpty {
                    EmptyFamilyView(viewModel: viewModel)
                } else {
                    FamilyContentView(viewModel: viewModel, showingMemberDetails: $showingMemberDetails)
                }
            }
            .navigationTitle("Family")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingCreateFamily = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateFamily) {
                CreateFamilySheet(viewModel: viewModel)
            }
            .sheet(item: $showingMemberDetails) { member in
                MemberDetailsSheet(member: member, viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadFamilies()
            }
        }
    }
}

// MARK: - Family Content View

struct FamilyContentView: View {
    @ObservedObject var viewModel: FamilyViewModel
    @Binding var showingMemberDetails: FamilyMember?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let family = viewModel.selectedFamily {
                    // Family info card
                    FamilyInfoCard(family: family.family, viewModel: viewModel)

                    // Members section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Family Members")
                                .font(.headline)
                            Spacer()
                            Text("\(family.members.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        ForEach(family.members) { member in
                            MemberRow(member: member) {
                                showingMemberDetails = member
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Devices section
                    if !family.devices.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Devices")
                                    .font(.headline)
                                Spacer()
                                Text("\(family.devices.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            ForEach(family.devices) { device in
                                DeviceRow(device: device)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.loadFamilies()
        }
    }
}

// MARK: - Empty Family View

struct EmptyFamilyView: View {
    @ObservedObject var viewModel: FamilyViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Family Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create a family to start managing screen time for your children")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: { viewModel.showingCreateFamily = true }) {
                Label("Create Family", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

// MARK: - Family Info Card

struct FamilyInfoCard: View {
    let family: Family
    @ObservedObject var viewModel: FamilyViewModel
    @State private var showingEditName = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(family.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Created \(family.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { showingEditName = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            Divider()

            // Invite code section
            VStack(alignment: .leading, spacing: 8) {
                Text("Invite Code")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                HStack {
                    Text(family.inviteCode)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)

                    Spacer()

                    Button(action: { viewModel.copyInviteCode(family.inviteCode) }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)

                    ShareLink(
                        item: viewModel.shareInviteCode(family.inviteCode),
                        preview: SharePreview("Family Invite")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .sheet(isPresented: $showingEditName) {
            EditFamilyNameSheet(family: family, viewModel: viewModel)
        }
    }
}

// MARK: - Member Row

struct MemberRow: View {
    let member: FamilyMember
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(roleColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text(member.userProfile?.initials ?? "?")
                        .font(.headline)
                        .foregroundColor(roleColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label(member.role.displayName, systemImage: roleIcon)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let email = member.userProfile?.email {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var roleColor: Color {
        switch member.role {
        case .admin, .parent:
            return .blue
        case .child:
            return .green
        }
    }

    private var roleIcon: String {
        switch member.role {
        case .admin:
            return "star.fill"
        case .parent:
            return "person.fill"
        case .child:
            return "person.circle.fill"
        }
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: Device

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.platform.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(device.deviceName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if device.isOnline {
                        Label("Online", systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label(device.lastSyncFormatted, systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    if let osVersion = device.osVersion {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(osVersion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if !device.isActive {
                Text("Inactive")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Create Family Sheet

struct CreateFamilySheet: View {
    @ObservedObject var viewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    @State private var familyName = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Family Name", text: $familyName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Family Information")
                } footer: {
                    Text("Choose a name for your family. You can change this later.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What happens next?", systemImage: "info.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 8) {
                            StepRow(number: 1, text: "Family created with unique invite code")
                            StepRow(number: 2, text: "Share invite code with children")
                            StepRow(number: 3, text: "Children join using the code")
                            StepRow(number: 4, text: "Configure rules and monitor usage")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Create Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createFamily(name: familyName)
                    }
                    .disabled(familyName.isEmpty)
                }
            }
        }
    }
}

struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .fontWeight(.semibold)
            Text(text)
        }
    }
}

// MARK: - Edit Family Name Sheet

struct EditFamilyNameSheet: View {
    let family: Family
    @ObservedObject var viewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    @State private var newName: String

    init(family: Family, viewModel: FamilyViewModel) {
        self.family = family
        self.viewModel = viewModel
        _newName = State(initialValue: family.name)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Family Name", text: $newName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Edit Family Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateFamilyName(newName, familyId: family.id)
                        dismiss()
                    }
                    .disabled(newName.isEmpty || newName == family.name)
                }
            }
        }
    }
}

// MARK: - Member Details Sheet

struct MemberDetailsSheet: View {
    let member: FamilyMember
    @ObservedObject var viewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingRemoveConfirmation = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(member.displayName)
                            .foregroundColor(.secondary)
                    }

                    if let email = member.userProfile?.email {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Role")
                        Spacer()
                        Label(member.role.displayName, systemImage: "person.fill")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Joined")
                        Spacer()
                        Text(member.joinedAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                }

                if member.isChild {
                    Section {
                        NavigationLink(destination: UsageReportsView(
                            childId: member.userId,
                            childName: member.displayName
                        )) {
                            Label("Usage Reports", systemImage: "chart.bar")
                        }

                        NavigationLink(destination: RulesManagementView()) {
                            Label("Screen Time Rules", systemImage: "list.bullet.clipboard")
                        }

                        NavigationLink(destination: AppCategorizationView()) {
                            Label("App Categorization", systemImage: "square.grid.2x2")
                        }
                    }
                }

                if !member.role.hasAdminPrivileges {
                    Section {
                        Button(role: .destructive, action: { showingRemoveConfirmation = true }) {
                            Label("Remove from Family", systemImage: "person.badge.minus")
                        }
                    }
                }
            }
            .navigationTitle("Member Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Remove Member", isPresented: $showingRemoveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    viewModel.removeMember(member)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to remove \(member.displayName) from the family?")
            }
        }
    }
}

// MARK: - Preview

struct FamilyManagementView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyManagementView()
    }
}
