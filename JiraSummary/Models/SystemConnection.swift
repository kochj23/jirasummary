//
//  SystemConnection.swift
//  JiraSummary
//
//  System connection configuration for Jira Cloud, Jira Server, and Azure DevOps
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

enum SystemType: String, Codable, CaseIterable, Identifiable {
    case jiraCloud = "Jira Cloud"
    case jiraServer = "Jira Server"
    case azureDevOps = "Azure DevOps"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .jiraCloud: return "cloud.fill"
        case .jiraServer: return "server.rack"
        case .azureDevOps: return "square.grid.3x3.fill"
        }
    }

    var loginPath: String {
        switch self {
        case .jiraCloud: return "/login"
        case .jiraServer: return "/login.jsp"
        case .azureDevOps: return "/_signin"
        }
    }
}

struct SystemConnection: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var type: SystemType
    var baseURL: URL
    var isAuthenticated: Bool
    var lastAuthDate: Date?
    var boardIds: [String]

    init(name: String, type: SystemType, baseURL: URL, boardIds: [String] = []) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.baseURL = baseURL
        self.isAuthenticated = false
        self.lastAuthDate = nil
        self.boardIds = boardIds
    }
}

enum AuthCredentialType: String, Codable {
    case cookie
    case bearerToken
    case basicAuth
}

struct AuthCredential: Codable {
    let systemId: UUID
    let type: AuthCredentialType
    let value: String
    let cookieName: String?
    let expiresAt: Date?
}
