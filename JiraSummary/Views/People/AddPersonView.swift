//
//  AddPersonView.swift
//  JiraSummary
//
//  Search and add a user from a connected system
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct AddPersonView: View {
    @Environment(\.dismiss) private var dismiss
    let connection: SystemConnection

    @State private var dataStore = DataStore.shared
    @State private var searchQuery = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var manualName = ""
    @State private var manualUserId = ""
    @State private var manualEmail = ""
    @State private var showManualEntry = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Person")
                        .modernHeader(size: .medium)

                    HStack(spacing: 6) {
                        Image(systemName: connection.type.icon)
                            .foregroundColor(ModernColors.systemTypeColor(connection.type))
                        Text(connection.name)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                }
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.textTertiary, style: .outlined))
            }
            .padding(24)

            Divider().background(ModernColors.glassBorder)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ModernColors.textTertiary)

                TextField("Search by name or email...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit { searchUsers() }

                if isSearching {
                    ProgressView().scaleEffect(0.7)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ModernColors.glassBorder, lineWidth: 1))
            )
            .padding(24)

            // Results
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(searchResults) { result in
                        searchResultRow(result)
                    }

                    if searchResults.isEmpty && !searchQuery.isEmpty && !isSearching {
                        Text("No users found")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                            .padding(.top, 20)
                    }

                    // Manual entry toggle
                    Button {
                        showManualEntry.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showManualEntry ? "chevron.down" : "chevron.right")
                            Text("Manual Entry")
                        }
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(ModernColors.accent)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)

                    if showManualEntry {
                        manualEntryForm
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .background(.ultraThickMaterial)
    }

    private func searchResultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(ModernColors.systemTypeColor(connection.type).opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(result.displayName.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.systemTypeColor(connection.type))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(result.displayName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)

                HStack(spacing: 6) {
                    Text(result.userId)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ModernColors.textTertiary)

                    if let email = result.email {
                        Text(email)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                }
            }

            Spacer()

            let alreadyAdded = dataStore.trackedPeople.contains { $0.systemUserId == result.userId && $0.systemId == connection.id }

            Button {
                addPerson(from: result)
            } label: {
                Text(alreadyAdded ? "Added" : "Add")
            }
            .buttonStyle(ModernButtonStyle(color: alreadyAdded ? ModernColors.textTertiary : ModernColors.cyan, style: alreadyAdded ? .outlined : .filled))
            .disabled(alreadyAdded)
        }
        .padding(12)
        .compactGlassCard()
    }

    private var manualEntryForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Display Name", text: $manualName)
                .textFieldStyle(.roundedBorder)

            TextField(userIdLabel, text: $manualUserId)
                .textFieldStyle(.roundedBorder)

            TextField("Email (optional)", text: $manualEmail)
                .textFieldStyle(.roundedBorder)

            Button("Add Person") {
                guard !manualName.isEmpty, !manualUserId.isEmpty else { return }
                let person = TrackedPerson(
                    systemId: connection.id,
                    displayName: manualName,
                    systemUserId: manualUserId,
                    emailAddress: manualEmail.isEmpty ? nil : manualEmail
                )
                dataStore.addPerson(person)
                manualName = ""
                manualUserId = ""
                manualEmail = ""
            }
            .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .filled))
            .disabled(manualName.isEmpty || manualUserId.isEmpty)
        }
        .padding(16)
        .compactGlassCard()
    }

    private var userIdLabel: String {
        switch connection.type {
        case .jiraCloud: return "Account ID"
        case .jiraServer: return "Username"
        case .azureDevOps: return "Unique Name (email)"
        }
    }

    // MARK: - Search

    private func searchUsers() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true

        Task {
            do {
                switch connection.type {
                case .jiraCloud:
                    let service = JiraCloudService(baseURL: connection.baseURL, systemId: connection.id)
                    let results = try await service.searchUsers(query: searchQuery)
                    searchResults = results.compactMap { user in
                        guard let accountId = user.accountId, let name = user.displayName else { return nil }
                        return SearchResult(
                            displayName: name,
                            userId: accountId,
                            email: user.emailAddress,
                            avatarURL: user.avatarUrls?._48x48.flatMap { URL(string: $0) }
                        )
                    }

                case .jiraServer:
                    let service = JiraServerService(baseURL: connection.baseURL, systemId: connection.id)
                    let results = try await service.searchUsers(query: searchQuery)
                    searchResults = results.compactMap { user in
                        guard let username = user.name, let name = user.displayName else { return nil }
                        return SearchResult(
                            displayName: name,
                            userId: username,
                            email: user.emailAddress,
                            avatarURL: user.avatarUrls?._48x48.flatMap { URL(string: $0) }
                        )
                    }

                case .azureDevOps:
                    // AzDO doesn't have a direct user search — search within team members
                    searchResults = []
                }
            } catch {
                searchResults = []
            }

            isSearching = false
        }
    }

    private func addPerson(from result: SearchResult) {
        let person = TrackedPerson(
            systemId: connection.id,
            displayName: result.displayName,
            systemUserId: result.userId,
            emailAddress: result.email,
            avatarURL: result.avatarURL
        )
        dataStore.addPerson(person)
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let displayName: String
    let userId: String
    let email: String?
    let avatarURL: URL?
}
