//
//  JiraServerService.swift
//  JiraSummary
//
//  Jira Server/Data Center REST API v2 client
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

actor JiraServerService {
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

    func searchIssues(jql: String, startAt: Int = 0, maxResults: Int = 50) async throws -> JiraSearchResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("/rest/api/2/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "jql", value: jql),
            URLQueryItem(name: "startAt", value: String(startAt)),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "expand", value: "changelog"),
            URLQueryItem(name: "fields", value: "summary,status,priority,issuetype,assignee,creator,created,updated,resolutiondate,customfield_10016,sprint")
        ]

        let request = try authenticatedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(JiraSearchResponse.self, from: data)
    }

    // MARK: - Fetch Issues for User

    func fetchIssuesForUser(username: String, since: Date) async throws -> [JiraIssue] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let sinceStr = dateFormatter.string(from: since)

        let jql = "(assignee = \"\(username)\" OR creator = \"\(username)\") AND updated >= \"\(sinceStr)\" ORDER BY updated DESC"

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
        return try JSONDecoder().decode(JiraSprintResponse.self, from: data).values
    }

    // MARK: - Boards

    func fetchBoards() async throws -> [JiraBoard] {
        let url = baseURL.appendingPathComponent("/rest/agile/1.0/board")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "maxResults", value: "50")
        ]

        let request = try authenticatedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(JiraBoardResponse.self, from: data).values
    }

    // MARK: - User Search

    func searchUsers(query: String) async throws -> [JiraUserSearchResult] {
        var components = URLComponents(url: baseURL.appendingPathComponent("/rest/api/2/user/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "username", value: query),
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
