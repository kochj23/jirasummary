//
//  ActivityTimelineView.swift
//  JiraSummary
//
//  Status transition timeline visualization
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct ActivityTimelineView: View {
    let activities: [TicketActivity]

    private var allTransitions: [(ticket: TicketActivity, transition: StatusTransition)] {
        activities.flatMap { activity in
            activity.transitions.map { (ticket: activity, transition: $0) }
        }
        .sorted { $0.transition.transitionDate > $1.transition.transitionDate }
    }

    private var groupedByDay: [(date: Date, items: [(ticket: TicketActivity, transition: StatusTransition)])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allTransitions) { item in
            calendar.startOfDay(for: item.transition.transitionDate)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, items: $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if allTransitions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 36))
                            .foregroundColor(ModernColors.textTertiary)

                        Text("No Activity Timeline")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)

                        Text("Status transitions will appear here after fetching data.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(groupedByDay, id: \.date) { group in
                        daySection(date: group.date, items: group.items)
                    }
                }
            }
            .padding(20)
        }
    }

    private func daySection(date: Date, items: [(ticket: TicketActivity, transition: StatusTransition)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date, style: .date)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)
                .padding(.bottom, 4)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 12) {
                    // Timeline line
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(ModernColors.glassBorder)
                                .frame(width: 1, height: 8)
                        }

                        Circle()
                            .fill(ModernColors.ticketStatusColor(item.transition.toStatus))
                            .frame(width: 10, height: 10)

                        if index < items.count - 1 {
                            Rectangle()
                                .fill(ModernColors.glassBorder)
                                .frame(width: 1, height: 8)
                        }
                    }
                    .frame(width: 10)

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(item.ticket.ticketKey)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(ModernColors.accent)

                            if let from = item.transition.fromStatus {
                                Text(from)
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(ModernColors.ticketStatusColor(from))

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(ModernColors.textTertiary)
                            }

                            Text(item.transition.toStatus)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(ModernColors.ticketStatusColor(item.transition.toStatus))
                        }

                        Text(item.ticket.title)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                            .lineLimit(1)

                        Text(item.transition.transitionDate, style: .time)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .compactGlassCard()
    }
}
