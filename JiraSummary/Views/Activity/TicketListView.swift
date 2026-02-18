//
//  TicketListView.swift
//  JiraSummary
//
//  Sortable ticket table
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct TicketListView: View {
    let activities: [TicketActivity]

    @State private var sortOrder = [KeyPathComparator(\TicketActivity.updatedDate, order: .reverse)]
    @State private var searchText = ""

    private var filteredActivities: [TicketActivity] {
        if searchText.isEmpty {
            return activities
        }
        return activities.filter {
            $0.ticketKey.localizedCaseInsensitiveContains(searchText) ||
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.currentStatus.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ModernColors.textTertiary)
                TextField("Filter tickets...", text: $searchText)
                    .textFieldStyle(.plain)
                Text("\(filteredActivities.count) tickets")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(ModernColors.textTertiary)
            }
            .padding(10)
            .background(Color.white.opacity(0.03))

            // Table
            Table(filteredActivities, sortOrder: $sortOrder) {
                TableColumn("Key", value: \.ticketKey) { activity in
                    Text(activity.ticketKey)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(ModernColors.accent)
                }
                .width(min: 80, ideal: 100)

                TableColumn("Title", value: \.title) { activity in
                    Text(activity.title)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                        .lineLimit(1)
                }
                .width(min: 200, ideal: 300)

                TableColumn("Status") { activity in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ModernColors.ticketStatusColor(activity.currentStatus))
                            .frame(width: 6, height: 6)
                        Text(activity.currentStatus)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                }
                .width(min: 100, ideal: 120)

                TableColumn("Type") { activity in
                    Text(activity.ticketType ?? "-")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
                .width(min: 60, ideal: 80)

                TableColumn("Points") { activity in
                    if let points = activity.storyPoints {
                        Text(String(format: "%.0f", points))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.purple)
                    } else {
                        Text("-")
                            .foregroundColor(ModernColors.textTertiary)
                    }
                }
                .width(min: 50, ideal: 60)

                TableColumn("Updated", value: \.updatedDate) { activity in
                    Text(activity.updatedDate, style: .relative)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
                .width(min: 80, ideal: 100)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: false))
        }
    }
}
