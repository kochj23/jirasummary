//
//  JiraCloudService.swift
//  JiraSummary
//
//  Jira Cloud REST API v3 client
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

actor JiraCloudService {
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

    // MARK: - Search Issues (JQL)

    func searchIssues(jql: String, startAt: Int = 0, maxResults: Int = 50, expand: [String] = ["changelog"]) async throws -> JiraSearchResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("/rest/api/3/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "jql", value: jql),
            URLQueryItem(name: "startAt", value: String(startAt)),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "expand", value: expand.joined(separator: ",")),
            URLQueryItem(name: "fields", value: "summary,status,priority,issuetype,assignee,creator,created,updated,resolutiondate,customfield_10016,sprint")
        ]

        let request = try authenticatedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(JiraSearchResponse.self, from: data)
    }

    // MARK: - Fetch Issues for User

    func fetchIssuesForUser(accountId: String, since: Date, boardId: String? = nil) async throws -> [JiraIssue] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let sinceStr = dateFormatter.string(from: since)

        var jql = "(assignee = \"\(accountId)\" OR creator = \"\(accountId)\") AND updated >= \"\(sinceStr)\""
        if let boardId = boardId {
            jql += " AND sprint in openSprints() AND board = \(boardId)"
        }
        jql += " ORDER BY updated DESC"

        var allIssues: [JiraIssue] = []
        var startAt = 0
        let pageSize = 50

        repeat {
            let response = try await searchIssues(jql: jql, startAt: startAt, maxResults: pageSize)
            allIssues.append(contentsOf: response.issues)
            startAt += pageSize
            if startAt >= response.total { break }
        } while true

        return allIssues
    }

    // MARK: - Sprint Data

    func fetchSprints(boardId: String) async throws -> [JiraSprint] {
        let url = baseURL.appendingPathComponent("/rest/agile/1.0/board/\(boardId)/sprint")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "state", value: "active,closed"),
            URLQueryItem(name: "maxResults", value: "10")
        ]

        let request = try authenticatedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        let sprintResponse = try JSONDecoder().decode(JiraSprintResponse.self, from: data)
        return sprintResponse.values
    }

    func fetchSprintIssues(sprintId: Int) async throws -> [JiraIssue] {
        let url = baseURL.appendingPathComponent("/rest/agile/1.0/sprint/\(sprintId)/issue")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "maxResults", value: "100"),
            URLQueryItem(name: "fields", value: "summary,status,priority,issuetype,assignee,creator,created,updated,resolutiondate,customfield_10016,sprint"),
            URLQueryItem(name: "expand", value: "changelog")
        ]

        let request = try authenticatedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(JiraSearchResponse.self, from: data).issues
    }

    // MARK: - Boards

    func fetchBoards() async throws -> [JiraBoard] {
        let url = baseURL.appendingPathComponent("/rest/agile/1.0/board")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "maxResults", value: "50"),
            URLQueryItem(name: "type", value: "scrum")
        ]

        let request = try authenticatedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(JiraBoardResponse.self, from: data).values
    }

    // MARK: - User Search

    func searchUsers(query: String) async throws -> [JiraUserSearchResult] {
        var components = URLComponents(url: baseURL.appendingPathComponent("/rest/api/3/user/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "maxResults", value: "20")
        ]

        let request = try authenticatedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode([JiraUserSearchResult].self, from: data)
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

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case rateLimited
    case httpError(Int)
    case decodingError(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "Authentication expired. Please re-authenticate."
        case .forbidden: return "Access denied. Check your permissions."
        case .rateLimited: return "Rate limited. Please wait and try again."
        case .httpError(let code): return "HTTP error \(code)"
        case .decodingError(let detail): return "Failed to parse response: \(detail)"
        case .noData: return "No data received"
        }
    }
}
