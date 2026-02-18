//
//  AzureDevOpsModels.swift
//  JiraSummary
//
//  Codable models for Azure DevOps REST API responses
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

// MARK: - Work Items

struct AzDOWiqlResponse: Codable {
    let queryType: String?
    let queryResultType: String?
    let workItems: [AzDOWorkItemReference]?
}

struct AzDOWorkItemReference: Codable {
    let id: Int
    let url: String?
}

struct AzDOWorkItemResponse: Codable {
    let count: Int?
    let value: [AzDOWorkItem]?
}

struct AzDOWorkItem: Codable {
    let id: Int
    let rev: Int?
    let fields: AzDOWorkItemFields?
    let url: String?

    struct AzDOWorkItemFields: Codable {
        let title: String?
        let state: String?
        let workItemType: String?
        let assignedTo: AzDOIdentity?
        let createdBy: AzDOIdentity?
        let createdDate: String?
        let changedDate: String?
        let closedDate: String?
        let priority: Int?
        let storyPoints: Double?
        let iterationPath: String?

        enum CodingKeys: String, CodingKey {
            case title = "System.Title"
            case state = "System.State"
            case workItemType = "System.WorkItemType"
            case assignedTo = "System.AssignedTo"
            case createdBy = "System.CreatedBy"
            case createdDate = "System.CreatedDate"
            case changedDate = "System.ChangedDate"
            case closedDate = "Microsoft.VSTS.Common.ClosedDate"
            case priority = "Microsoft.VSTS.Common.Priority"
            case storyPoints = "Microsoft.VSTS.Scheduling.StoryPoints"
            case iterationPath = "System.IterationPath"
        }
    }
}

struct AzDOIdentity: Codable {
    let displayName: String?
    let uniqueName: String?
    let id: String?
    let imageUrl: String?
}

// MARK: - Updates (for status transitions)

struct AzDOWorkItemUpdatesResponse: Codable {
    let count: Int?
    let value: [AzDOWorkItemUpdate]?
}

struct AzDOWorkItemUpdate: Codable {
    let id: Int?
    let rev: Int?
    let revisedBy: AzDOIdentity?
    let revisedDate: String?
    let fields: AzDOUpdateFields?

    struct AzDOUpdateFields: Codable {
        let state: AzDOFieldUpdate?

        enum CodingKeys: String, CodingKey {
            case state = "System.State"
        }
    }
}

struct AzDOFieldUpdate: Codable {
    let oldValue: String?
    let newValue: String?
}

// MARK: - Iterations (Sprints)

struct AzDOIterationsResponse: Codable {
    let count: Int?
    let value: [AzDOIteration]?
}

struct AzDOIteration: Codable {
    let id: String?
    let name: String?
    let path: String?
    let attributes: AzDOIterationAttributes?
    let url: String?
}

struct AzDOIterationAttributes: Codable {
    let startDate: String?
    let finishDate: String?
    let timeFrame: String?
}

// MARK: - Team Members

struct AzDOTeamMembersResponse: Codable {
    let count: Int?
    let value: [AzDOTeamMember]?
}

struct AzDOTeamMember: Codable {
    let identity: AzDOIdentity?
    let isTeamAdmin: Bool?
}

// MARK: - Projects

struct AzDOProjectsResponse: Codable {
    let count: Int?
    let value: [AzDOProject]?
}

struct AzDOProject: Codable {
    let id: String?
    let name: String?
    let description: String?
    let url: String?
    let state: String?
}
