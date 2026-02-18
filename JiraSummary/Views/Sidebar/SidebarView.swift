//
//  SidebarView.swift
//  JiraSummary
//
//  Navigation sidebar with dashboard, systems, people, and settings
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: NavItem?
    @State private var dataStore = DataStore.shared
    @State private var coordinator = DataFetchCoordinator.shared

    var body: some View {
        VStack(spacing: 0) {
            // App Header
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ModernColors.cyan, ModernColors.accentBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Jira Summary")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
            }
            .padding(.vertical, 20)

            Divider()
                .background(ModernColors.glassBorder)
                .padding(.horizontal, 16)

            // Navigation Items
            VStack(spacing: 4) {
                ForEach(NavItem.allCases) { item in
                    SidebarButton(
                        item: item,
                        isSelected: selection == item,
                        badge: badgeCount(for: item)
                    ) {
                        selection = item
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)

            Spacer()

            // Status footer
            VStack(spacing: 8) {
                if coordinator.isFetching {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(ModernColors.cyan)

                        Text(coordinator.fetchProgress)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                            .lineLimit(1)
                    }
                } else if let lastRefresh = dataStore.lastRefreshDate {
                    let formatter = RelativeDateTimeFormatter()
                    Text("Updated \(formatter.localizedString(for: lastRefresh, relativeTo: Date()))")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }

                Button {
                    Task { await coordinator.fetchAll() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.cyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ModernColors.cyan.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(ModernColors.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(coordinator.isFetching)
            }
            .padding(16)
        }
        .background(.ultraThinMaterial)
    }

    private func badgeCount(for item: NavItem) -> Int? {
        switch item {
        case .dashboard:
            let blocked = dataStore.personSummaries.reduce(0) { $0 + $1.ticketsBlocked }
            return blocked > 0 ? blocked : nil
        case .systems:
            return dataStore.connections.isEmpty ? nil : dataStore.connections.count
        case .people:
            return dataStore.trackedPeople.isEmpty ? nil : dataStore.trackedPeople.count
        case .settings:
            return nil
        }
    }
}

struct SidebarButton: View {
    let item: NavItem
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? ModernColors.cyan : ModernColors.textSecondary)
                    .frame(width: 24)

                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? ModernColors.textPrimary : ModernColors.textSecondary)

                Spacer()

                if let badge = badge {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? ModernColors.cyan : ModernColors.textTertiary)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ModernColors.cyan.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? ModernColors.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
