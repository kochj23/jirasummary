//
//  TicketActivityTests.swift
//  JiraSummaryTests
//
//  Unit tests for TicketActivity and StatusTransition models
//  Created by Jordan Koch on 2026-05-01.
//

import XCTest
@testable import JiraSummary

final class TicketActivityTests: XCTestCase {

    // MARK: - TicketActivity Creation

    func testTicketActivityInit() {
        let systemId = UUID()
        let personId = UUID()
        let activity = TicketActivity(
            systemId: systemId,
            personId: personId,
            ticketKey: "PROJ-100",
            title: "Fix critical bug",
            currentStatus: "In Progress"
        )

        XCTAssertEqual(activity.systemId, systemId)
        XCTAssertEqual(activity.personId, personId)
        XCTAssertEqual(activity.ticketKey, "PROJ-100")
        XCTAssertEqual(activity.title, "Fix critical bug")
        XCTAssertEqual(activity.currentStatus, "In Progress")
        XCTAssertTrue(activity.transitions.isEmpty)
        XCTAssertNil(activity.priority)
        XCTAssertNil(activity.ticketType)
        XCTAssertNil(activity.storyPoints)
        XCTAssertNil(activity.resolvedDate)
        XCTAssertNil(activity.ticketURL)
        XCTAssertNil(activity.sprintName)
    }

    func testTicketActivityUniqueIds() {
        let activity1 = TicketActivity(systemId: UUID(), personId: UUID(), ticketKey: "A-1", title: "First", currentStatus: "Open")
        let activity2 = TicketActivity(systemId: UUID(), personId: UUID(), ticketKey: "A-2", title: "Second", currentStatus: "Open")

        XCTAssertNotEqual(activity1.id, activity2.id, "Each TicketActivity should have a unique UUID")
    }

    func testTicketActivityHashable() {
        let activity = TicketActivity(systemId: UUID(), personId: UUID(), ticketKey: "H-1", title: "Hashable", currentStatus: "Done")
        var set = Set<TicketActivity>()
        set.insert(activity)
        set.insert(activity) // duplicate

        XCTAssertEqual(set.count, 1, "Duplicate insertion should not increase set count")
    }

    // MARK: - TicketActivity Codable

    func testTicketActivityCodableRoundTrip() throws {
        var activity = TicketActivity(
            systemId: UUID(),
            personId: UUID(),
            ticketKey: "RT-1",
            title: "Round trip test",
            currentStatus: "Done"
        )
        activity.priority = "High"
        activity.ticketType = "Bug"
        activity.storyPoints = 3.0
        activity.sprintName = "Sprint 10"
        activity.resolvedDate = Date()
        activity.transitions = [
            StatusTransition(fromStatus: "Open", toStatus: "In Progress", transitionDate: Date(), author: "Dev"),
            StatusTransition(fromStatus: "In Progress", toStatus: "Done", transitionDate: Date(), author: "Dev")
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(activity)
        let decoded = try JSONDecoder().decode(TicketActivity.self, from: data)

        XCTAssertEqual(decoded.id, activity.id)
        XCTAssertEqual(decoded.ticketKey, "RT-1")
        XCTAssertEqual(decoded.title, "Round trip test")
        XCTAssertEqual(decoded.currentStatus, "Done")
        XCTAssertEqual(decoded.priority, "High")
        XCTAssertEqual(decoded.ticketType, "Bug")
        XCTAssertEqual(decoded.storyPoints, 3.0)
        XCTAssertEqual(decoded.sprintName, "Sprint 10")
        XCTAssertNotNil(decoded.resolvedDate)
        XCTAssertEqual(decoded.transitions.count, 2)
    }

    // MARK: - StatusTransition

    func testStatusTransitionInit() {
        let now = Date()
        let transition = StatusTransition(
            fromStatus: "To Do",
            toStatus: "In Progress",
            transitionDate: now,
            author: "Jane Developer"
        )

        XCTAssertEqual(transition.fromStatus, "To Do")
        XCTAssertEqual(transition.toStatus, "In Progress")
        XCTAssertEqual(transition.transitionDate, now)
        XCTAssertEqual(transition.author, "Jane Developer")
    }

    func testStatusTransitionWithNilFromStatus() {
        let transition = StatusTransition(
            fromStatus: nil,
            toStatus: "Open",
            transitionDate: Date(),
            author: nil
        )

        XCTAssertNil(transition.fromStatus, "New tickets may have nil fromStatus")
        XCTAssertNil(transition.author, "Automated transitions may have nil author")
    }

    func testStatusTransitionHashable() {
        let date = Date()
        let t1 = StatusTransition(fromStatus: "A", toStatus: "B", transitionDate: date, author: "X")
        let t2 = StatusTransition(fromStatus: "A", toStatus: "B", transitionDate: date, author: "X")

        XCTAssertEqual(t1, t2)
    }

    func testStatusTransitionCodable() throws {
        let transition = StatusTransition(fromStatus: "Open", toStatus: "Closed", transitionDate: Date(), author: "Bot")
        let data = try JSONEncoder().encode(transition)
        let decoded = try JSONDecoder().decode(StatusTransition.self, from: data)

        XCTAssertEqual(decoded.fromStatus, "Open")
        XCTAssertEqual(decoded.toStatus, "Closed")
        XCTAssertEqual(decoded.author, "Bot")
    }

    // MARK: - Mutable Properties

    func testTicketActivityMutableFields() {
        var activity = TicketActivity(systemId: UUID(), personId: UUID(), ticketKey: "MUT-1", title: "Mutable", currentStatus: "Open")

        activity.currentStatus = "Closed"
        activity.priority = "Critical"
        activity.storyPoints = 13.0
        activity.ticketURL = URL(string: "https://jira.example.com/browse/MUT-1")

        XCTAssertEqual(activity.currentStatus, "Closed")
        XCTAssertEqual(activity.priority, "Critical")
        XCTAssertEqual(activity.storyPoints, 13.0)
        XCTAssertEqual(activity.ticketURL?.absoluteString, "https://jira.example.com/browse/MUT-1")
    }
}
