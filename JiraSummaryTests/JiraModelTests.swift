//
//  JiraModelTests.swift
//  JiraSummaryTests
//
//  Unit tests for Jira REST API Codable model parsing
//  Created by Jordan Koch on 2026-05-01.
//

import XCTest
@testable import JiraSummary

final class JiraModelTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - JiraSearchResponse

    func testDecodeJiraSearchResponse() throws {
        let json = """
        {
            "startAt": 0,
            "maxResults": 50,
            "total": 2,
            "issues": [
                {
                    "id": "10001",
                    "key": "PROJ-123",
                    "fields": {
                        "summary": "Fix login bug",
                        "status": { "name": "In Progress", "id": "3" }
                    }
                },
                {
                    "id": "10002",
                    "key": "PROJ-124",
                    "fields": {
                        "summary": "Add dark mode",
                        "status": { "name": "Done", "id": "5" }
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(JiraSearchResponse.self, from: json)
        XCTAssertEqual(response.startAt, 0)
        XCTAssertEqual(response.maxResults, 50)
        XCTAssertEqual(response.total, 2)
        XCTAssertEqual(response.issues.count, 2)
        XCTAssertEqual(response.issues[0].key, "PROJ-123")
        XCTAssertEqual(response.issues[0].fields.summary, "Fix login bug")
        XCTAssertEqual(response.issues[1].fields.status.name, "Done")
    }

    func testDecodeEmptySearchResponse() throws {
        let json = """
        {
            "startAt": 0,
            "maxResults": 50,
            "total": 0,
            "issues": []
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(JiraSearchResponse.self, from: json)
        XCTAssertEqual(response.total, 0)
        XCTAssertTrue(response.issues.isEmpty)
    }

    // MARK: - JiraIssue with Full Fields

    func testDecodeJiraIssueWithAllFields() throws {
        let json = """
        {
            "id": "10050",
            "key": "TEAM-42",
            "self": "https://example.atlassian.net/rest/api/3/issue/10050",
            "fields": {
                "summary": "Implement caching layer",
                "status": {
                    "name": "Code Review",
                    "id": "10001",
                    "statusCategory": { "id": 4, "key": "indeterminate", "name": "In Progress" }
                },
                "priority": { "name": "High", "id": "2" },
                "issuetype": { "name": "Story", "id": "10001", "subtask": false },
                "assignee": {
                    "displayName": "Jane Developer",
                    "accountId": "5b10a2844c20165700ede21g",
                    "emailAddress": "jane@example.com"
                },
                "creator": {
                    "displayName": "John Manager",
                    "accountId": "5b10a2844c20165700ede21f"
                },
                "created": "2026-04-15T10:30:00.000+0000",
                "updated": "2026-04-28T14:22:00.000+0000",
                "resolutiondate": null,
                "customfield_10016": 5.0,
                "sprint": {
                    "id": 42,
                    "name": "Sprint 23",
                    "state": "active",
                    "startDate": "2026-04-14T00:00:00.000Z",
                    "endDate": "2026-04-28T00:00:00.000Z",
                    "goal": "Complete caching epic"
                }
            },
            "changelog": {
                "histories": [
                    {
                        "id": "100",
                        "created": "2026-04-20T09:00:00.000+0000",
                        "author": { "displayName": "Jane Developer" },
                        "items": [
                            {
                                "field": "status",
                                "fromString": "To Do",
                                "toString": "In Progress"
                            }
                        ]
                    },
                    {
                        "id": "101",
                        "created": "2026-04-26T11:00:00.000+0000",
                        "author": { "displayName": "Jane Developer" },
                        "items": [
                            {
                                "field": "status",
                                "fromString": "In Progress",
                                "toString": "Code Review"
                            }
                        ]
                    }
                ]
            }
        }
        """.data(using: .utf8)!

        let issue = try decoder.decode(JiraIssue.self, from: json)
        XCTAssertEqual(issue.id, "10050")
        XCTAssertEqual(issue.key, "TEAM-42")
        XCTAssertEqual(issue.fields.summary, "Implement caching layer")
        XCTAssertEqual(issue.fields.status.name, "Code Review")
        XCTAssertEqual(issue.fields.status.statusCategory?.name, "In Progress")
        XCTAssertEqual(issue.fields.priority?.name, "High")
        XCTAssertEqual(issue.fields.issuetype?.name, "Story")
        XCTAssertEqual(issue.fields.issuetype?.subtask, false)
        XCTAssertEqual(issue.fields.assignee?.displayName, "Jane Developer")
        XCTAssertEqual(issue.fields.assignee?.accountId, "5b10a2844c20165700ede21g")
        XCTAssertEqual(issue.fields.creator?.displayName, "John Manager")
        XCTAssertEqual(issue.fields.customfield_10016, 5.0)
        XCTAssertEqual(issue.fields.sprint?.name, "Sprint 23")
        XCTAssertEqual(issue.fields.sprint?.state, "active")
        XCTAssertEqual(issue.fields.sprint?.goal, "Complete caching epic")
        XCTAssertNotNil(issue.changelog)
        XCTAssertEqual(issue.changelog?.histories?.count, 2)
        XCTAssertEqual(issue.changelog?.histories?[0].items?[0].field, "status")
        XCTAssertEqual(issue.changelog?.histories?[0].items?[0].fromString, "To Do")
        XCTAssertEqual(issue.changelog?.histories?[0].items?[0].toString, "In Progress")
    }

    func testDecodeJiraIssueMinimalFields() throws {
        let json = """
        {
            "id": "99",
            "key": "MIN-1",
            "fields": {
                "summary": "Minimal issue",
                "status": { "name": "Open" }
            }
        }
        """.data(using: .utf8)!

        let issue = try decoder.decode(JiraIssue.self, from: json)
        XCTAssertEqual(issue.key, "MIN-1")
        XCTAssertNil(issue.fields.priority)
        XCTAssertNil(issue.fields.issuetype)
        XCTAssertNil(issue.fields.assignee)
        XCTAssertNil(issue.fields.customfield_10016)
        XCTAssertNil(issue.fields.sprint)
        XCTAssertNil(issue.changelog)
    }

    // MARK: - JiraSprint

    func testDecodeJiraSprintResponse() throws {
        let json = """
        {
            "maxResults": 50,
            "startAt": 0,
            "values": [
                {
                    "id": 10,
                    "name": "Sprint 22",
                    "state": "closed",
                    "startDate": "2026-04-01T00:00:00.000Z",
                    "endDate": "2026-04-14T00:00:00.000Z"
                },
                {
                    "id": 11,
                    "name": "Sprint 23",
                    "state": "active",
                    "startDate": "2026-04-14T00:00:00.000Z",
                    "endDate": "2026-04-28T00:00:00.000Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(JiraSprintResponse.self, from: json)
        XCTAssertEqual(response.values.count, 2)
        XCTAssertEqual(response.values[0].name, "Sprint 22")
        XCTAssertEqual(response.values[0].state, "closed")
        XCTAssertEqual(response.values[1].state, "active")
    }

    // MARK: - JiraBoard

    func testDecodeJiraBoardResponse() throws {
        let json = """
        {
            "maxResults": 50,
            "startAt": 0,
            "values": [
                { "id": 1, "name": "Scrum Board", "type": "scrum" },
                { "id": 2, "name": "Kanban Board", "type": "kanban" }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(JiraBoardResponse.self, from: json)
        XCTAssertEqual(response.values.count, 2)
        XCTAssertEqual(response.values[0].name, "Scrum Board")
        XCTAssertEqual(response.values[0].type, "scrum")
    }

    // MARK: - JiraUserSearchResult

    func testDecodeJiraCloudUserSearchResults() throws {
        let json = """
        [
            {
                "accountId": "5b10a2844c20165700ede21g",
                "displayName": "Jane Developer",
                "emailAddress": "jane@example.com",
                "active": true,
                "avatarUrls": { "48x48": "https://example.com/avatar.png", "32x32": "https://example.com/avatar32.png" }
            }
        ]
        """.data(using: .utf8)!

        let results = try decoder.decode([JiraUserSearchResult].self, from: json)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].accountId, "5b10a2844c20165700ede21g")
        XCTAssertEqual(results[0].displayName, "Jane Developer")
        XCTAssertEqual(results[0].active, true)
        XCTAssertNotNil(results[0].avatarUrls)
    }

    func testDecodeJiraServerUserSearchResults() throws {
        let json = """
        [
            {
                "name": "jdeveloper",
                "displayName": "Jane Developer",
                "emailAddress": "jane@company.com",
                "active": true
            }
        ]
        """.data(using: .utf8)!

        let results = try decoder.decode([JiraUserSearchResult].self, from: json)
        XCTAssertEqual(results[0].name, "jdeveloper")
        XCTAssertNil(results[0].accountId)
    }

    // MARK: - JiraChangeHistory

    func testDecodeChangelogWithMultipleFields() throws {
        let json = """
        {
            "histories": [
                {
                    "id": "200",
                    "created": "2026-04-25T09:30:00.000+0000",
                    "author": { "displayName": "Bot User" },
                    "items": [
                        { "field": "status", "fromString": "Open", "toString": "In Progress" },
                        { "field": "assignee", "fromString": null, "toString": "Jane Developer" }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let changelog = try decoder.decode(JiraChangelog.self, from: json)
        XCTAssertEqual(changelog.histories?.count, 1)
        XCTAssertEqual(changelog.histories?[0].items?.count, 2)
        XCTAssertEqual(changelog.histories?[0].items?[0].field, "status")
        XCTAssertEqual(changelog.histories?[0].items?[1].field, "assignee")
        XCTAssertNil(changelog.histories?[0].items?[1].fromString)
    }

    // MARK: - Encoding Round-Trip

    func testJiraStatusCategoryRoundTrip() throws {
        let category = JiraStatusCategory(id: 3, key: "done", name: "Done")
        let encoded = try JSONEncoder().encode(category)
        let decoded = try decoder.decode(JiraStatusCategory.self, from: encoded)
        XCTAssertEqual(decoded.id, 3)
        XCTAssertEqual(decoded.key, "done")
        XCTAssertEqual(decoded.name, "Done")
    }
}
