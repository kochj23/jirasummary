//
//  AddSystemView.swift
//  JiraSummary
//
//  Add a new Jira or Azure DevOps connection
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct AddSystemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dataStore = DataStore.shared
    @State private var name = ""
    @State private var baseURLString = ""
    @State private var selectedType: SystemType = .jiraCloud
    @State private var boardIdsText = ""
    @State private var validationError: String?
    @State private var showSSOAuth = false
    @State private var newConnection: SystemConnection?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add System")
                    .modernHeader(size: .medium)
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.textTertiary, style: .outlined))
            }
            .padding(24)

            Divider().background(ModernColors.glassBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // System type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Type")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)

                        Picker("Type", selection: $selectedType) {
                            ForEach(SystemType.allCases) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)

                        TextField("e.g., Corp Jira, Team Azure", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Base URL
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Base URL")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)

                        TextField(urlPlaceholder, text: $baseURLString)
                            .textFieldStyle(.roundedBorder)

                        Text(urlHint)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }

                    // Board IDs (Jira only)
                    if selectedType != .azureDevOps {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Board IDs (optional, comma-separated)")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(ModernColors.textSecondary)

                            TextField("e.g., 42, 108", text: $boardIdsText)
                                .textFieldStyle(.roundedBorder)

                            Text("Used for sprint velocity data. Find board IDs in the board URL.")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(ModernColors.textTertiary)
                        }
                    }

                    // Validation error
                    if let error = validationError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(ModernColors.accentOrange)
                            Text(error)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(ModernColors.accentOrange)
                        }
                    }
                }
                .padding(24)
            }

            Divider().background(ModernColors.glassBorder)

            // Actions
            HStack {
                Spacer()
                Button("Add & Authenticate") {
                    addSystem()
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .filled))
                .disabled(name.isEmpty || baseURLString.isEmpty)
            }
            .padding(24)
        }
        .background(.ultraThickMaterial)
        .sheet(isPresented: $showSSOAuth) {
            if let connection = newConnection {
                SSOWebView(connection: connection)
                    .frame(minWidth: 800, minHeight: 600)
            }
        }
    }

    private var urlPlaceholder: String {
        switch selectedType {
        case .jiraCloud: return "https://yourcompany.atlassian.net"
        case .jiraServer: return "https://jira.yourcompany.com"
        case .azureDevOps: return "https://dev.azure.com/yourorg"
        }
    }

    private var urlHint: String {
        switch selectedType {
        case .jiraCloud: return "Your Atlassian Cloud URL (e.g., https://company.atlassian.net)"
        case .jiraServer: return "Your Jira Server/Data Center URL"
        case .azureDevOps: return "Your Azure DevOps organization URL"
        }
    }

    private func addSystem() {
        validationError = nil

        // Validate URL
        var urlString = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.hasPrefix("http") { urlString = "https://\(urlString)" }
        if urlString.hasSuffix("/") { urlString = String(urlString.dropLast()) }

        guard let url = URL(string: urlString) else {
            validationError = "Invalid URL format"
            return
        }

        // Parse board IDs
        let boardIds = boardIdsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let connection = SystemConnection(
            name: name.trimmingCharacters(in: .whitespaces),
            type: selectedType,
            baseURL: url,
            boardIds: boardIds
        )

        dataStore.addConnection(connection)
        newConnection = connection
        showSSOAuth = true
    }
}
