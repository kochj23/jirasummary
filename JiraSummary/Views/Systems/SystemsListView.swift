//
//  SystemsListView.swift
//  JiraSummary
//
//  Manage system connections (Jira Cloud, Jira Server, Azure DevOps)
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct SystemsListView: View {
    @State private var dataStore = DataStore.shared
    @State private var showAddSystem = false
    @State private var showSSOAuth: SystemConnection?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Systems")
                            .modernHeader(size: .large)

                        Text("Manage Jira and Azure DevOps connections")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        showAddSystem = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Add System")
                        }
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .filled))
                }
                .padding(.horizontal, 24)

                // Systems list
                if dataStore.connections.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(dataStore.connections) { connection in
                            systemCard(for: connection)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 24)
        }
        .sheet(isPresented: $showAddSystem) {
            AddSystemView()
                .frame(minWidth: 500, minHeight: 400)
        }
        .sheet(item: $showSSOAuth) { connection in
            SSOWebView(connection: connection)
                .frame(minWidth: 800, minHeight: 600)
        }
    }

    private func systemCard(for connection: SystemConnection) -> some View {
        HStack(spacing: 16) {
            // Type icon
            Image(systemName: connection.type.icon)
                .font(.system(size: 28))
                .foregroundColor(ModernColors.systemTypeColor(connection.type))
                .frame(width: 44)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(connection.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)

                Text(connection.baseURL.absoluteString)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(ModernColors.textTertiary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(connection.type.rawValue)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.systemTypeColor(connection.type))

                    if !connection.boardIds.isEmpty {
                        Text("\(connection.boardIds.count) board(s)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }

                    let peopleCount = dataStore.people(for: connection.id).count
                    if peopleCount > 0 {
                        Text("\(peopleCount) people")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                }
            }

            Spacer()

            // Auth status
            VStack(spacing: 6) {
                Circle()
                    .fill(connection.isAuthenticated ? ModernColors.accentGreen : ModernColors.accentRed)
                    .frame(width: 10, height: 10)

                Text(connection.isAuthenticated ? "Connected" : "Not Authenticated")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(connection.isAuthenticated ? ModernColors.accentGreen : ModernColors.accentRed)
            }

            // Actions
            VStack(spacing: 4) {
                if !connection.isAuthenticated {
                    Button("Authenticate") {
                        showSSOAuth = connection
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .outlined))
                } else {
                    Button("Re-auth") {
                        showSSOAuth = connection
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.textTertiary, style: .outlined))
                }

                Button("Remove") {
                    KeychainService.shared.deleteCredential(for: connection.id)
                    dataStore.removeConnection(connection.id)
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.accentRed, style: .destructive))
            }
        }
        .padding(20)
        .compactGlassCard()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundColor(ModernColors.textTertiary)

            Text("No Systems Connected")
                .modernHeader(size: .medium)

            Text("Add a Jira Cloud, Jira Server, or Azure DevOps connection to get started.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(ModernColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button {
                showAddSystem = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First System")
                }
            }
            .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .filled))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
