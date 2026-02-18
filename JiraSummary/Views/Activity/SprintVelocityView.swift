//
//  SprintVelocityView.swift
//  JiraSummary
//
//  Sprint velocity visualization (committed vs completed)
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI
import Charts

struct SprintVelocityView: View {
    let sprints: [SprintData]
    let personId: UUID?

    init(sprints: [SprintData], personId: UUID? = nil) {
        self.sprints = sprints
        self.personId = personId
    }

    private var sortedSprints: [SprintData] {
        sprints
            .filter { $0.state == .closed || $0.state == .active }
            .sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
            .suffix(8)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if sortedSprints.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 36))
                            .foregroundColor(ModernColors.textTertiary)

                        Text("No Sprint Data")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)

                        Text("Add board IDs to your system connection to track sprint velocity.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // Chart
                    Chart {
                        ForEach(sortedSprints) { sprint in
                            let committed = personCommitted(sprint)
                            let completed = personCompleted(sprint)

                            BarMark(
                                x: .value("Sprint", sprint.sprintName),
                                y: .value("Points", committed)
                            )
                            .foregroundStyle(ModernColors.accentBlue.opacity(0.5))
                            .position(by: .value("Type", "Committed"))

                            BarMark(
                                x: .value("Sprint", sprint.sprintName),
                                y: .value("Points", completed)
                            )
                            .foregroundStyle(ModernColors.accentGreen)
                            .position(by: .value("Type", "Completed"))
                        }
                    }
                    .chartForegroundStyleScale([
                        "Committed": ModernColors.accentBlue.opacity(0.5),
                        "Completed": ModernColors.accentGreen
                    ])
                    .chartYAxisLabel("Story Points")
                    .frame(height: 250)
                    .padding(20)
                    .compactGlassCard()

                    // Sprint list
                    ForEach(sortedSprints.reversed()) { sprint in
                        sprintRow(sprint)
                    }
                }
            }
            .padding(20)
        }
    }

    private func sprintRow(_ sprint: SprintData) -> some View {
        let committed = personCommitted(sprint)
        let completed = personCompleted(sprint)
        let velocity = committed > 0 ? (completed / committed) * 100 : 0

        return HStack(spacing: 16) {
            // State indicator
            Circle()
                .fill(sprint.state == .active ? ModernColors.accentGreen : ModernColors.textTertiary)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(sprint.sprintName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)

                if let goal = sprint.goal {
                    Text(goal)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                        .lineLimit(1)
                }

                if let start = sprint.startDate, let end = sprint.endDate {
                    Text("\(start, style: .date) — \(end, style: .date)")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
            }

            Spacer()

            // Velocity
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f/%.0f pts", completed, committed))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)

                Text(String(format: "%.0f%% velocity", velocity))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(velocity >= 80 ? ModernColors.accentGreen : velocity >= 50 ? ModernColors.accentOrange : ModernColors.accentRed)
            }

            CircularGauge(value: velocity, color: velocity >= 80 ? ModernColors.accentGreen : ModernColors.accentOrange, size: 36, lineWidth: 3, showValue: false)
        }
        .padding(14)
        .compactGlassCard()
    }

    private func personCommitted(_ sprint: SprintData) -> Double {
        if let personId, let breakdown = sprint.personBreakdowns.first(where: { $0.personId == personId }) {
            return breakdown.committedPoints
        }
        return sprint.committedPoints
    }

    private func personCompleted(_ sprint: SprintData) -> Double {
        if let personId, let breakdown = sprint.personBreakdowns.first(where: { $0.personId == personId }) {
            return breakdown.completedPoints
        }
        return sprint.completedPoints
    }
}
