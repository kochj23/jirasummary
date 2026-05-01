//
//  PersonSummaryTests.swift
//  JiraSummaryTests
//
//  Unit tests for PersonSummary model and SummaryPeriod
//  Created by Jordan Koch on 2026-05-01.
//

import XCTest
@testable import JiraSummary

final class PersonSummaryTests: XCTestCase {

    // MARK: - PersonSummary Init

    func testPersonSummaryInitDefaults() {
        let personId = UUID()
        let systemId = UUID()
        let summary = PersonSummary(
            personId: personId,
            systemId: systemId,
            personName: "Jane Developer",
            systemName: "Jira Cloud",
            period: .weekly
        )

        XCTAssertEqual(summary.personId, personId)
        XCTAssertEqual(summary.systemId, systemId)
        XCTAssertEqual(summary.personName, "Jane Developer")
        XCTAssertEqual(summary.systemName, "Jira Cloud")
        XCTAssertEqual(summary.period, .weekly)
        XCTAssertEqual(summary.ticketsCreated, 0)
        XCTAssertEqual(summary.ticketsInProgress, 0)
        XCTAssertEqual(summary.ticketsCompleted, 0)
        XCTAssertEqual(summary.ticketsBlocked, 0)
        XCTAssertEqual(summary.totalTickets, 0)
        XCTAssertEqual(summary.committedPoints, 0)
        XCTAssertEqual(summary.completedPoints, 0)
        XCTAssertEqual(summary.carryOverPoints, 0)
        XCTAssertTrue(summary.recentTickets.isEmpty)
        XCTAssertTrue(summary.recentTransitions.isEmpty)
        XCTAssertNil(summary.aiSummary)
        XCTAssertNil(summary.sprintName)
    }

    // MARK: - Velocity Percentage

    func testVelocityPercentageNormal() {
        var summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Test", systemName: "Sys", period: .sprint)
        summary.committedPoints = 20
        summary.completedPoints = 15

        XCTAssertEqual(summary.velocityPercentage, 75.0, accuracy: 0.01)
    }

    func testVelocityPercentageFullCompletion() {
        var summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Test", systemName: "Sys", period: .sprint)
        summary.committedPoints = 10
        summary.completedPoints = 10

        XCTAssertEqual(summary.velocityPercentage, 100.0, accuracy: 0.01)
    }

    func testVelocityPercentageOverCompletion() {
        var summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Test", systemName: "Sys", period: .sprint)
        summary.committedPoints = 10
        summary.completedPoints = 12

        XCTAssertEqual(summary.velocityPercentage, 120.0, accuracy: 0.01)
    }

    func testVelocityPercentageZeroCommitted() {
        var summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Test", systemName: "Sys", period: .sprint)
        summary.committedPoints = 0
        summary.completedPoints = 5

        XCTAssertEqual(summary.velocityPercentage, 0, "Should return 0 to avoid division by zero")
    }

    func testVelocityPercentageBothZero() {
        let summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Test", systemName: "Sys", period: .sprint)
        XCTAssertEqual(summary.velocityPercentage, 0)
    }

    // MARK: - Completion Rate

    func testCompletionRateNormal() {
        var summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Test", systemName: "Sys", period: .weekly)
        summary.totalTickets = 10
        summary.ticketsCompleted = 7

        XCTAssertEqual(summary.completionRate, 70.0, accuracy: 0.01)
    }

    func testCompletionRateZeroTickets() {
        let summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Test", systemName: "Sys", period: .weekly)
        XCTAssertEqual(summary.completionRate, 0, "Should return 0 to avoid division by zero")
    }

    func testCompletionRateAllCompleted() {
        var summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Test", systemName: "Sys", period: .daily)
        summary.totalTickets = 5
        summary.ticketsCompleted = 5

        XCTAssertEqual(summary.completionRate, 100.0, accuracy: 0.01)
    }

    func testCompletionRateNoneCompleted() {
        var summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Test", systemName: "Sys", period: .daily)
        summary.totalTickets = 3
        summary.ticketsCompleted = 0

        XCTAssertEqual(summary.completionRate, 0.0)
    }

    // MARK: - SummaryPeriod

    func testSummaryPeriodDays() {
        XCTAssertEqual(SummaryPeriod.daily.days, 1)
        XCTAssertEqual(SummaryPeriod.weekly.days, 7)
        XCTAssertEqual(SummaryPeriod.sprint.days, 14)
        XCTAssertEqual(SummaryPeriod.monthly.days, 30)
    }

    func testSummaryPeriodRawValues() {
        XCTAssertEqual(SummaryPeriod.daily.rawValue, "Daily")
        XCTAssertEqual(SummaryPeriod.weekly.rawValue, "Weekly")
        XCTAssertEqual(SummaryPeriod.sprint.rawValue, "Sprint")
        XCTAssertEqual(SummaryPeriod.monthly.rawValue, "Monthly")
    }

    func testSummaryPeriodAllCases() {
        XCTAssertEqual(SummaryPeriod.allCases.count, 4)
    }

    func testSummaryPeriodCodable() throws {
        for period in SummaryPeriod.allCases {
            let data = try JSONEncoder().encode(period)
            let decoded = try JSONDecoder().decode(SummaryPeriod.self, from: data)
            XCTAssertEqual(decoded, period)
        }
    }

    // MARK: - PersonSummary Codable

    func testPersonSummaryCodableRoundTrip() throws {
        var summary = PersonSummary(personId: UUID(), systemId: UUID(), personName: "Alice", systemName: "Azure DevOps", period: .monthly)
        summary.ticketsCreated = 5
        summary.ticketsInProgress = 3
        summary.ticketsCompleted = 12
        summary.ticketsBlocked = 1
        summary.totalTickets = 21
        summary.committedPoints = 30
        summary.completedPoints = 24
        summary.carryOverPoints = 6
        summary.sprintName = "Sprint 15"
        summary.aiSummary = "Alice had a productive month."

        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(PersonSummary.self, from: data)

        XCTAssertEqual(decoded.id, summary.id)
        XCTAssertEqual(decoded.personName, "Alice")
        XCTAssertEqual(decoded.systemName, "Azure DevOps")
        XCTAssertEqual(decoded.period, .monthly)
        XCTAssertEqual(decoded.ticketsCreated, 5)
        XCTAssertEqual(decoded.ticketsCompleted, 12)
        XCTAssertEqual(decoded.totalTickets, 21)
        XCTAssertEqual(decoded.committedPoints, 30)
        XCTAssertEqual(decoded.completedPoints, 24)
        XCTAssertEqual(decoded.sprintName, "Sprint 15")
        XCTAssertEqual(decoded.aiSummary, "Alice had a productive month.")
    }
}
