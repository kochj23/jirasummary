//
//  SprintDataTests.swift
//  JiraSummaryTests
//
//  Unit tests for SprintData and PersonSprintBreakdown models
//  Created by Jordan Koch on 2026-05-01.
//

import XCTest
@testable import JiraSummary

final class SprintDataTests: XCTestCase {

    // MARK: - SprintData Init

    func testSprintDataDefaultInit() {
        let systemId = UUID()
        let sprint = SprintData(systemId: systemId, sprintName: "Sprint 10")

        XCTAssertEqual(sprint.systemId, systemId)
        XCTAssertEqual(sprint.sprintName, "Sprint 10")
        XCTAssertEqual(sprint.state, .active)
        XCTAssertEqual(sprint.committedPoints, 0)
        XCTAssertEqual(sprint.completedPoints, 0)
        XCTAssertEqual(sprint.carryOverPoints, 0)
        XCTAssertEqual(sprint.totalIssues, 0)
        XCTAssertEqual(sprint.completedIssues, 0)
        XCTAssertNil(sprint.boardName)
        XCTAssertNil(sprint.startDate)
        XCTAssertNil(sprint.endDate)
        XCTAssertNil(sprint.goal)
        XCTAssertTrue(sprint.personBreakdowns.isEmpty)
    }

    func testSprintDataClosedState() {
        let sprint = SprintData(systemId: UUID(), sprintName: "Sprint 9", state: .closed)
        XCTAssertEqual(sprint.state, .closed)
    }

    func testSprintDataFutureState() {
        let sprint = SprintData(systemId: UUID(), sprintName: "Sprint 11", state: .future)
        XCTAssertEqual(sprint.state, .future)
    }

    // MARK: - Velocity Percentage

    func testVelocityPercentageNormal() {
        var sprint = SprintData(systemId: UUID(), sprintName: "V-Test")
        sprint.committedPoints = 40
        sprint.completedPoints = 30

        XCTAssertEqual(sprint.velocityPercentage, 75.0, accuracy: 0.01)
    }

    func testVelocityPercentageZeroCommitted() {
        let sprint = SprintData(systemId: UUID(), sprintName: "V-Zero")
        XCTAssertEqual(sprint.velocityPercentage, 0, "Should return 0 when committedPoints is 0")
    }

    func testVelocityPercentagePerfect() {
        var sprint = SprintData(systemId: UUID(), sprintName: "V-Perfect")
        sprint.committedPoints = 25
        sprint.completedPoints = 25

        XCTAssertEqual(sprint.velocityPercentage, 100.0, accuracy: 0.01)
    }

    // MARK: - SprintState

    func testSprintStateCodable() throws {
        for state in [SprintState.future, .active, .closed] {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(SprintState.self, from: data)
            XCTAssertEqual(decoded, state)
        }
    }

    func testSprintStateRawValues() {
        XCTAssertEqual(SprintState.future.rawValue, "future")
        XCTAssertEqual(SprintState.active.rawValue, "active")
        XCTAssertEqual(SprintState.closed.rawValue, "closed")
    }

    // MARK: - PersonSprintBreakdown

    func testPersonSprintBreakdownInit() {
        let personId = UUID()
        let breakdown = PersonSprintBreakdown(personId: personId, personName: "Bob Builder")

        XCTAssertEqual(breakdown.personId, personId)
        XCTAssertEqual(breakdown.personName, "Bob Builder")
        XCTAssertEqual(breakdown.committedPoints, 0)
        XCTAssertEqual(breakdown.completedPoints, 0)
        XCTAssertEqual(breakdown.issuesCompleted, 0)
        XCTAssertEqual(breakdown.issuesTotal, 0)
    }

    func testPersonSprintBreakdownCodable() throws {
        var breakdown = PersonSprintBreakdown(personId: UUID(), personName: "Coder")
        breakdown.committedPoints = 10
        breakdown.completedPoints = 8
        breakdown.issuesTotal = 5
        breakdown.issuesCompleted = 4

        let data = try JSONEncoder().encode(breakdown)
        let decoded = try JSONDecoder().decode(PersonSprintBreakdown.self, from: data)

        XCTAssertEqual(decoded.personName, "Coder")
        XCTAssertEqual(decoded.committedPoints, 10)
        XCTAssertEqual(decoded.completedPoints, 8)
        XCTAssertEqual(decoded.issuesTotal, 5)
        XCTAssertEqual(decoded.issuesCompleted, 4)
    }

    // MARK: - SprintData Codable

    func testSprintDataCodableRoundTrip() throws {
        var sprint = SprintData(systemId: UUID(), sprintName: "Sprint 20", state: .active)
        sprint.boardName = "Main Board"
        sprint.startDate = Date()
        sprint.endDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())
        sprint.goal = "Ship v2.0"
        sprint.committedPoints = 50
        sprint.completedPoints = 35
        sprint.carryOverPoints = 15
        sprint.totalIssues = 20
        sprint.completedIssues = 14
        sprint.personBreakdowns = [
            PersonSprintBreakdown(personId: UUID(), personName: "Dev1")
        ]

        let data = try JSONEncoder().encode(sprint)
        let decoded = try JSONDecoder().decode(SprintData.self, from: data)

        XCTAssertEqual(decoded.id, sprint.id)
        XCTAssertEqual(decoded.sprintName, "Sprint 20")
        XCTAssertEqual(decoded.boardName, "Main Board")
        XCTAssertEqual(decoded.goal, "Ship v2.0")
        XCTAssertEqual(decoded.committedPoints, 50)
        XCTAssertEqual(decoded.completedPoints, 35)
        XCTAssertEqual(decoded.totalIssues, 20)
        XCTAssertEqual(decoded.personBreakdowns.count, 1)
    }

    // MARK: - SprintData Hashable

    func testSprintDataHashable() {
        let sprint = SprintData(systemId: UUID(), sprintName: "Hash Sprint")
        var set = Set<SprintData>()
        set.insert(sprint)
        set.insert(sprint)
        XCTAssertEqual(set.count, 1)
    }
}
