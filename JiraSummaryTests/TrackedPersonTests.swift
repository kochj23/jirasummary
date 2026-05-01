//
//  TrackedPersonTests.swift
//  JiraSummaryTests
//
//  Unit tests for TrackedPerson model
//  Created by Jordan Koch on 2026-05-01.
//

import XCTest
@testable import JiraSummary

final class TrackedPersonTests: XCTestCase {

    // MARK: - Init

    func testTrackedPersonInit() {
        let systemId = UUID()
        let person = TrackedPerson(
            systemId: systemId,
            displayName: "Jane Developer",
            systemUserId: "5b10a2844c20165700ede21g"
        )

        XCTAssertEqual(person.systemId, systemId)
        XCTAssertEqual(person.displayName, "Jane Developer")
        XCTAssertEqual(person.systemUserId, "5b10a2844c20165700ede21g")
        XCTAssertNil(person.emailAddress)
        XCTAssertNil(person.avatarURL)
        XCTAssertNotNil(person.dateAdded)
    }

    func testTrackedPersonWithOptionalFields() {
        let avatarURL = URL(string: "https://example.com/avatar.png")!
        let person = TrackedPerson(
            systemId: UUID(),
            displayName: "Bob Manager",
            systemUserId: "bob.manager",
            emailAddress: "bob@example.com",
            avatarURL: avatarURL
        )

        XCTAssertEqual(person.emailAddress, "bob@example.com")
        XCTAssertEqual(person.avatarURL, avatarURL)
    }

    // MARK: - Codable

    func testTrackedPersonCodableRoundTrip() throws {
        let person = TrackedPerson(
            systemId: UUID(),
            displayName: "Test Person",
            systemUserId: "test-id",
            emailAddress: "test@co.com",
            avatarURL: URL(string: "https://avatar.example.com/pic.jpg")
        )

        let data = try JSONEncoder().encode(person)
        let decoded = try JSONDecoder().decode(TrackedPerson.self, from: data)

        XCTAssertEqual(decoded.id, person.id)
        XCTAssertEqual(decoded.systemId, person.systemId)
        XCTAssertEqual(decoded.displayName, "Test Person")
        XCTAssertEqual(decoded.systemUserId, "test-id")
        XCTAssertEqual(decoded.emailAddress, "test@co.com")
        XCTAssertEqual(decoded.avatarURL?.absoluteString, "https://avatar.example.com/pic.jpg")
    }

    // MARK: - Hashable

    func testTrackedPersonHashable() {
        let person = TrackedPerson(systemId: UUID(), displayName: "Unique", systemUserId: "u-1")
        var set = Set<TrackedPerson>()
        set.insert(person)
        set.insert(person)

        XCTAssertEqual(set.count, 1)
    }

    func testTrackedPersonUniqueIds() {
        let systemId = UUID()
        let p1 = TrackedPerson(systemId: systemId, displayName: "Person", systemUserId: "user1")
        let p2 = TrackedPerson(systemId: systemId, displayName: "Person", systemUserId: "user1")

        XCTAssertNotEqual(p1.id, p2.id, "Two separate instances should have different UUIDs")
    }
}
