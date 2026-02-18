//
//  PeopleListView.swift
//  JiraSummary
//
//  Per-system tracked people management
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct PeopleListView: View {
    @State private var dataStore = DataStore.shared
    @State private var showAddPerson = false
    @State private var selectedSystem: SystemConnection?
    @State private var selectedPerson: TrackedPerson?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("People")
                            .modernHeader(size: .large)

                        Text("Track team members across connected systems")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }

                    Spacer()

                    if !dataStore.connections.isEmpty {
                        Menu {
                            ForEach(dataStore.connections.filter { $0.isAuthenticated }) { conn in
                                Button {
                                    selectedSystem = conn
                                    showAddPerson = true
                                } label: {
                                    Label(conn.name, systemImage: conn.type.icon)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.badge.plus")
                                Text("Add Person")
                            }
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .filled))
                    }
                }
                .padding(.horizontal, 24)

                // Group by system
                if dataStore.trackedPeople.isEmpty {
                    emptyState
                } else {
                    ForEach(dataStore.connections) { connection in
                        let people = dataStore.people(for: connection.id)
                        if !people.isEmpty {
                            systemPeopleSection(connection: connection, people: people)
                        }
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .sheet(isPresented: $showAddPerson) {
            if let system = selectedSystem {
                AddPersonView(connection: system)
                    .frame(minWidth: 500, minHeight: 400)
            }
        }
        .sheet(item: $selectedPerson) { person in
            PersonDetailView(person: person)
                .frame(minWidth: 700, minHeight: 500)
        }
    }

    private func systemPeopleSection(connection: SystemConnection, people: [TrackedPerson]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: connection.type.icon)
                    .foregroundColor(ModernColors.systemTypeColor(connection.type))
                Text(connection.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
                Text("(\(people.count))")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(ModernColors.textTertiary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 8) {
                ForEach(people) { person in
                    personRow(person: person, connection: connection)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func personRow(person: TrackedPerson, connection: SystemConnection) -> some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(ModernColors.systemTypeColor(connection.type).opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(person.displayName.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.systemTypeColor(connection.type))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(person.displayName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)

                HStack(spacing: 6) {
                    Text(person.systemUserId)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ModernColors.textTertiary)

                    if let email = person.emailAddress {
                        Text(email)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                }
            }

            Spacer()

            // Activity summary
            let summary = dataStore.personSummaries.first { $0.personId == person.id }
            if let s = summary {
                HStack(spacing: 8) {
                    Text("\(s.ticketsCompleted) done")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.accentGreen)

                    Text("\(s.ticketsInProgress) active")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.accentBlue)
                }
            }

            Button {
                selectedPerson = person
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(ModernColors.textTertiary)
            }
            .buttonStyle(.plain)

            Button {
                dataStore.removePerson(person.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(ModernColors.accentRed.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .compactGlassCard()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(ModernColors.textTertiary)

            Text("No People Tracked")
                .modernHeader(size: .medium)

            if dataStore.connections.filter({ $0.isAuthenticated }).isEmpty {
                Text("Authenticate a system connection first, then add team members.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Add team members from your connected systems to track their activity.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
