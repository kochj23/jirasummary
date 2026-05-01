//
//  AzureDevOpsModelTests.swift
//  JiraSummaryTests
//
//  Unit tests for Azure DevOps REST API Codable model parsing
//  Created by Jordan Koch on 2026-05-01.
//

import XCTest
@testable import JiraSummary

final class AzureDevOpsModelTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - WIQL Response

    func testDecodeWiqlResponse() throws {
        let json = """
        {
            "queryType": "flat",
            "queryResultType": "workItem",
            "workItems": [
                { "id": 1001, "url": "https://dev.azure.com/org/project/_apis/wit/workitems/1001" },
                { "id": 1002, "url": "https://dev.azure.com/org/project/_apis/wit/workitems/1002" }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AzDOWiqlResponse.self, from: json)
        XCTAssertEqual(response.queryType, "flat")
        XCTAssertEqual(response.workItems?.count, 2)
        XCTAssertEqual(response.workItems?[0].id, 1001)
    }

    func testDecodeEmptyWiqlResponse() throws {
        let json = """
        {
            "queryType": "flat",
            "queryResultType": "workItem",
            "workItems": []
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AzDOWiqlResponse.self, from: json)
        XCTAssertTrue(response.workItems?.isEmpty ?? true)
    }

    // MARK: - Work Items

    func testDecodeWorkItemResponse() throws {
        let json = """
        {
            "count": 1,
            "value": [
                {
                    "id": 42,
                    "rev": 5,
                    "fields": {
                        "System.Title": "Implement feature X",
                        "System.State": "Active",
                        "System.WorkItemType": "User Story",
                        "System.AssignedTo": {
                            "displayName": "John Smith",
                            "uniqueName": "john@company.com",
                            "id": "abc-123"
                        },
                        "System.CreatedBy": {
                            "displayName": "Product Owner",
                            "uniqueName": "po@company.com"
                        },
                        "System.CreatedDate": "2026-04-01T10:00:00Z",
                        "System.ChangedDate": "2026-04-25T14:30:00Z",
                        "Microsoft.VSTS.Common.Priority": 2,
                        "Microsoft.VSTS.Scheduling.StoryPoints": 8.0,
                        "System.IterationPath": "Project\\\\Sprint 5"
                    },
                    "url": "https://dev.azure.com/org/project/_apis/wit/workitems/42"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AzDOWorkItemResponse.self, from: json)
        XCTAssertEqual(response.count, 1)
        XCTAssertEqual(response.value?.count, 1)

        let item = try XCTUnwrap(response.value?.first)
        XCTAssertEqual(item.id, 42)
        XCTAssertEqual(item.rev, 5)
        XCTAssertEqual(item.fields?.title, "Implement feature X")
        XCTAssertEqual(item.fields?.state, "Active")
        XCTAssertEqual(item.fields?.workItemType, "User Story")
        XCTAssertEqual(item.fields?.assignedTo?.displayName, "John Smith")
        XCTAssertEqual(item.fields?.assignedTo?.uniqueName, "john@company.com")
        XCTAssertEqual(item.fields?.priority, 2)
        XCTAssertEqual(item.fields?.storyPoints, 8.0)
    }

    func testDecodeWorkItemWithNullFields() throws {
        let json = """
        {
            "id": 99,
            "rev": 1,
            "fields": {
                "System.Title": "Bug report",
                "System.State": "New"
            }
        }
        """.data(using: .utf8)!

        let item = try decoder.decode(AzDOWorkItem.self, from: json)
        XCTAssertEqual(item.id, 99)
        XCTAssertEqual(item.fields?.title, "Bug report")
        XCTAssertNil(item.fields?.assignedTo)
        XCTAssertNil(item.fields?.storyPoints)
        XCTAssertNil(item.fields?.closedDate)
    }

    // MARK: - Work Item Updates

    func testDecodeWorkItemUpdatesResponse() throws {
        let json = """
        {
            "count": 2,
            "value": [
                {
                    "id": 1,
                    "rev": 1,
                    "revisedBy": { "displayName": "PM", "uniqueName": "pm@co.com" },
                    "revisedDate": "2026-04-10T09:00:00Z"
                },
                {
                    "id": 2,
                    "rev": 2,
                    "revisedBy": { "displayName": "Dev", "uniqueName": "dev@co.com" },
                    "revisedDate": "2026-04-12T11:00:00Z",
                    "fields": {
                        "System.State": {
                            "oldValue": "New",
                            "newValue": "Active"
                        }
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AzDOWorkItemUpdatesResponse.self, from: json)
        XCTAssertEqual(response.count, 2)
        XCTAssertEqual(response.value?.count, 2)
        XCTAssertNil(response.value?[0].fields)
        XCTAssertEqual(response.value?[1].fields?.state?.oldValue, "New")
        XCTAssertEqual(response.value?[1].fields?.state?.newValue, "Active")
    }

    // MARK: - Iterations

    func testDecodeIterationsResponse() throws {
        let json = """
        {
            "count": 1,
            "value": [
                {
                    "id": "iter-001",
                    "name": "Sprint 5",
                    "path": "Project\\\\Sprint 5",
                    "attributes": {
                        "startDate": "2026-04-14T00:00:00Z",
                        "finishDate": "2026-04-28T00:00:00Z",
                        "timeFrame": "current"
                    },
                    "url": "https://dev.azure.com/org/project/_apis/work/teamsettings/iterations/iter-001"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AzDOIterationsResponse.self, from: json)
        XCTAssertEqual(response.value?.count, 1)
        XCTAssertEqual(response.value?[0].name, "Sprint 5")
        XCTAssertEqual(response.value?[0].attributes?.timeFrame, "current")
    }

    // MARK: - Team Members

    func testDecodeTeamMembersResponse() throws {
        let json = """
        {
            "count": 2,
            "value": [
                {
                    "identity": {
                        "displayName": "Lead Dev",
                        "uniqueName": "lead@co.com",
                        "id": "id-lead"
                    },
                    "isTeamAdmin": true
                },
                {
                    "identity": {
                        "displayName": "Junior Dev",
                        "uniqueName": "junior@co.com",
                        "id": "id-junior"
                    },
                    "isTeamAdmin": false
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AzDOTeamMembersResponse.self, from: json)
        XCTAssertEqual(response.value?.count, 2)
        XCTAssertEqual(response.value?[0].isTeamAdmin, true)
        XCTAssertEqual(response.value?[1].identity?.displayName, "Junior Dev")
    }

    // MARK: - Projects

    func testDecodeProjectsResponse() throws {
        let json = """
        {
            "count": 1,
            "value": [
                {
                    "id": "proj-uuid",
                    "name": "My Project",
                    "description": "A cool project",
                    "url": "https://dev.azure.com/org/_apis/projects/proj-uuid",
                    "state": "wellFormed"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AzDOProjectsResponse.self, from: json)
        XCTAssertEqual(response.value?.count, 1)
        XCTAssertEqual(response.value?[0].name, "My Project")
        XCTAssertEqual(response.value?[0].state, "wellFormed")
    }

    // MARK: - AzDOIdentity

    func testDecodeAzDOIdentity() throws {
        let json = """
        {
            "displayName": "Test User",
            "uniqueName": "test@example.com",
            "id": "unique-id-123",
            "imageUrl": "https://dev.azure.com/org/_api/_common/identityImage?id=unique-id-123"
        }
        """.data(using: .utf8)!

        let identity = try decoder.decode(AzDOIdentity.self, from: json)
        XCTAssertEqual(identity.displayName, "Test User")
        XCTAssertEqual(identity.uniqueName, "test@example.com")
        XCTAssertEqual(identity.id, "unique-id-123")
        XCTAssertNotNil(identity.imageUrl)
    }
}
