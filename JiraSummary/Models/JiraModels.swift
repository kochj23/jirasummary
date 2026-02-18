//
//  JiraModels.swift
//  JiraSummary
//
//  Codable models for Jira Cloud (v3) and Jira Server (v2) REST API responses
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

// MARK: - Common Jira Models

struct JiraSearchResponse: Codable {
    let startAt: Int
    let maxResults: Int
    let total: Int
    let issues: [JiraIssue]
}

struct JiraIssue: Codable {
    let id: String
    let key: String
    let `self`: String?
    let fields: JiraIssueFields
    let changelog: JiraChangelog?
}

struct JiraIssueFields: Codable {
    let summary: String
    let status: JiraStatus
    let priority: JiraPriority?
    let issuetype: JiraIssueType?
    let assignee: JiraUser?
    let creator: JiraUser?
    let created: String?
    let updated: String?
    let resolutiondate: String?
    let customfield_10016: Double? // Story points (common field)
    let sprint: JiraSprint?

    enum CodingKeys: String, CodingKey {
        case summary, status, priority, issuetype, assignee, creator
        case created, updated, resolutiondate
        case customfield_10016
        case sprint
    }
}

struct JiraStatus: Codable {
    let name: String
    let id: String?
    let statusCategory: JiraStatusCategory?
}

struct JiraStatusCategory: Codable {
    let id: Int?
    let key: String?
    let name: String?
}

struct JiraPriority: Codable {
    let name: String
    let id: String?
}

struct JiraIssueType: Codable {
    let name: String
    let id: String?
    let subtask: Bool?
}

struct JiraUser: Codable {
    let displayName: String?
    let accountId: String?  // Jira Cloud
    let name: String?       // Jira Server
    let emailAddress: String?
    let avatarUrls: JiraAvatarUrls?
}

struct JiraAvatarUrls: Codable {
    let _48x48: String?
    let _32x32: String?

    enum CodingKeys: String, CodingKey {
        case _48x48 = "48x48"
        case _32x32 = "32x32"
    }
}

// MARK: - Changelog

struct JiraChangelog: Codable {
    let histories: [JiraChangeHistory]?
}

struct JiraChangeHistory: Codable {
    let id: String?
    let created: String?
    let author: JiraUser?
    let items: [JiraChangeItem]?
}

struct JiraChangeItem: Codable {
    let field: String?
    let fromString: String?
    let toString: String?
}

// MARK: - Sprint / Board

struct JiraSprint: Codable {
    let id: Int
    let name: String
    let state: String?
    let startDate: String?
    let endDate: String?
    let goal: String?
}

struct JiraSprintResponse: Codable {
    let maxResults: Int
    let startAt: Int
    let values: [JiraSprint]
}

struct JiraBoardResponse: Codable {
    let maxResults: Int
    let startAt: Int
    let values: [JiraBoard]
}

struct JiraBoard: Codable {
    let id: Int
    let name: String
    let type: String?
}

// MARK: - User Search

struct JiraUserSearchResult: Codable {
    let accountId: String?  // Cloud
    let name: String?       // Server
    let displayName: String?
    let emailAddress: String?
    let avatarUrls: JiraAvatarUrls?
    let active: Bool?
}
