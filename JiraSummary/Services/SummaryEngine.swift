//
//  SummaryEngine.swift
//  JiraSummary
//
//  Aggregates raw ticket and sprint data into PersonSummary
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

final class SummaryEngine {
    static let shared = SummaryEngine()

    private init() {}

    func generateSummary(
        for person: TrackedPerson,
        systemName: String,
        activities: [TicketActivity],
        sprints: [SprintData],
        period: SummaryPeriod
    ) -> PersonSummary {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -period.days, to: Date()) ?? Date()

        // Filter activities within period
        let periodActivities = activities.filter { $0.updatedDate >= cutoffDate }

        var summary = PersonSummary(
            personId: person.id,
            systemId: person.systemId,
            personName: person.displayName,
            systemName: systemName,
            period: period
        )

        // Count ticket statuses
        let doneStatuses = Set(["done", "closed", "resolved", "completed"])
        let progressStatuses = Set(["in progress", "active", "doing", "in review", "code review", "testing"])
        let blockedStatuses = Set(["blocked", "impediment"])

        summary.totalTickets = periodActivities.count
        summary.ticketsCompleted = periodActivities.filter { doneStatuses.contains($0.currentStatus.lowercased()) }.count
        summary.ticketsInProgress = periodActivities.filter { progressStatuses.contains($0.currentStatus.lowercased()) }.count
        summary.ticketsBlocked = periodActivities.filter { blockedStatuses.contains($0.currentStatus.lowercased()) }.count
        summary.ticketsCreated = periodActivities.filter { $0.createdDate >= cutoffDate }.count

        // Sprint velocity for this person
        if let activeSprint = sprints.first(where: { $0.state == .active }) {
            summary.sprintName = activeSprint.sprintName
            if let breakdown = activeSprint.personBreakdowns.first(where: { $0.personId == person.id }) {
                summary.committedPoints = breakdown.committedPoints
                summary.completedPoints = breakdown.completedPoints
            }
        } else {
            // Calculate from story points on tickets
            summary.committedPoints = periodActivities.compactMap { $0.storyPoints }.reduce(0, +)
            summary.completedPoints = periodActivities
                .filter { doneStatuses.contains($0.currentStatus.lowercased()) }
                .compactMap { $0.storyPoints }
                .reduce(0, +)
        }

        // Recent activity (last 10 tickets)
        summary.recentTickets = Array(periodActivities.sorted { $0.updatedDate > $1.updatedDate }.prefix(10))

        // Recent transitions (last 20)
        summary.recentTransitions = Array(
            periodActivities
                .flatMap { $0.transitions }
                .sorted { $0.transitionDate > $1.transitionDate }
                .prefix(20)
        )

        return summary
    }
}
