//
//  AzureDevOpsService.swift
//  JiraSummary
//
//  Azure DevOps REST API 7.1 client
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

actor AzureDevOpsService {
    private let baseURL: URL
    private let systemId: UUID
    private let session: URLSession

    init(baseURL: URL, systemId: UUID) {
        self.baseURL = baseURL
        self.systemId = systemId

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - WIQL Escaping & Validation

    private func escapeWIQL(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "''")
    }

    private static let validProjectNameRegex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9_\\- .]+$")

    private func validateProjectName(_ project: String) throws {
        let range = NSRange(project.startIndex..<project.endIndex, in: project)
        guard Self.validProjectNameRegex.firstMatch(in: project, range: range) != nil else {
            throw APIError.invalidParameter("Project name contains invalid characters")
        }
    }

    // MARK: - Projects

    func fetchProjects() async throws -> [AzDOProject] {
        let url = baseURL.appendingPathComponent("/_apis/projects")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "api-version", value: "7.1"),
            URLQueryItem(name: "$top", value: "50")
        ]

        guard let requestURL = components.url else { throw APIError.invalidURL }
        let request = try authenticatedRequest(url: requestURL)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(AzDOProjectsResponse.self, from: data).value ?? []
    }

    // MARK: - Work Items via WIQL

    func queryWorkItems(wiql: String) async throws -> [AzDOWorkItem] {
        // Step 1: Execute WIQL query to get work item IDs
        let wiqlURL = baseURL.appendingPathComponent("/_apis/wit/wiql")
        guard var components = URLComponents(url: wiqlURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "api-version", value: "7.1")]

        guard let requestURL = components.url else { throw APIError.invalidURL }
        var request = try authenticatedRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["query": wiql]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let wiqlResponse = try JSONDecoder().decode(AzDOWiqlResponse.self, from: data)
        guard let workItemRefs = wiqlResponse.workItems, !workItemRefs.isEmpty else {
            return []
        }

        // Step 2: Fetch full work item details in batches of 200
        var allWorkItems: [AzDOWorkItem] = []
        let batchSize = 200

        for batchStart in stride(from: 0, to: workItemRefs.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, workItemRefs.count)
            let batchIds = workItemRefs[batchStart..<batchEnd].map { String($0.id) }.joined(separator: ",")

            let itemsURL = baseURL.appendingPathComponent("/_apis/wit/workitems")
            guard var itemComponents = URLComponents(url: itemsURL, resolvingAgainstBaseURL: false) else {
                throw APIError.invalidURL
            }
            itemComponents.queryItems = [
                URLQueryItem(name: "ids", value: batchIds),
                URLQueryItem(name: "api-version", value: "7.1"),
                URLQueryItem(name: "$expand", value: "all")
            ]

            guard let itemURL = itemComponents.url else { throw APIError.invalidURL }
            let itemRequest = try authenticatedRequest(url: itemURL)
            let (itemData, itemResponse) = try await session.data(for: itemRequest)
            try validateResponse(itemResponse)

            let itemsResponse = try JSONDecoder().decode(AzDOWorkItemResponse.self, from: itemData)
            if let items = itemsResponse.value {
                allWorkItems.append(contentsOf: items)
            }
        }

        return allWorkItems
    }

    // MARK: - Fetch Work Items for User

    func fetchWorkItemsForUser(uniqueName: String, since: Date, project: String? = nil) async throws -> [AzDOWorkItem] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let sinceStr = dateFormatter.string(from: since)

        let escapedUniqueName = escapeWIQL(uniqueName)

        var projectScope = ""
        if let project = project {
            try validateProjectName(project)
            let escapedProject = escapeWIQL(project)
            projectScope = "[\(escapedProject)]."
        }

        let wiql = """
        SELECT [System.Id]
        FROM WorkItems
        WHERE (\(projectScope)[System.AssignedTo] = '\(escapedUniqueName)'
               OR \(projectScope)[System.CreatedBy] = '\(escapedUniqueName)')
        AND [System.ChangedDate] >= '\(sinceStr)'
        ORDER BY [System.ChangedDate] DESC
        """

        return try await queryWorkItems(wiql: wiql)
    }

    // MARK: - Work Item Updates (Status Transitions)

    func fetchWorkItemUpdates(workItemId: Int) async throws -> [AzDOWorkItemUpdate] {
        let url = baseURL.appendingPathComponent("/_apis/wit/workitems/\(workItemId)/updates")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "api-version", value: "7.1")]

        guard let requestURL = components.url else { throw APIError.invalidURL }
        let request = try authenticatedRequest(url: requestURL)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        return try JSONDecoder().decode(AzDOWorkItemUpdatesResponse.self, from: data).value ?? []
    }

    // MARK: - Iterations (Sprints)

    func fetchIterations(project: String, team: String? = nil) async throws -> [AzDOIteration] {
        let teamPath = team.map { "/\($0)" } ?? ""
        let url = baseURL.appendingPathComponent("/\(project)\(teamPath)/_apis/work/teamsettings/iterations")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "api-version", value: "7.1"),
            URLQueryItem(name: "$timeframe", value: "current")
        ]

        guard let requestURL = components.url else { throw APIError.invalidURL }
        let request = try authenticatedRequest(url: requestURL)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        return try JSONDecoder().decode(AzDOIterationsResponse.self, from: data).value ?? []
    }

    // MARK: - Team Members

    func fetchTeamMembers(project: String, team: String) async throws -> [AzDOTeamMember] {
        let url = baseURL.appendingPathComponent("/_apis/projects/\(project)/teams/\(team)/members")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "api-version", value: "7.1")]

        guard let requestURL = components.url else { throw APIError.invalidURL }
        let request = try authenticatedRequest(url: requestURL)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        return try JSONDecoder().decode(AzDOTeamMembersResponse.self, from: data).value ?? []
    }

    // MARK: - Auth & Helpers

    private func authenticatedRequest(url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let credential = KeychainService.shared.retrieveCredential(for: systemId) {
            switch credential.type {
            case .cookie:
                if let cookieName = credential.cookieName {
                    request.setValue("\(cookieName)=\(credential.value)", forHTTPHeaderField: "Cookie")
                }
            case .bearerToken:
                request.setValue("Bearer \(credential.value)", forHTTPHeaderField: "Authorization")
            case .basicAuth:
                request.setValue("Basic \(credential.value)", forHTTPHeaderField: "Authorization")
            }
        }

        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299: return
        case 401: throw APIError.unauthorized
        case 403: throw APIError.forbidden
        case 429: throw APIError.rateLimited
        default: throw APIError.httpError(httpResponse.statusCode)
        }
    }
}
