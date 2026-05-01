//
//  SystemConnectionTests.swift
//  JiraSummaryTests
//
//  Unit tests for SystemConnection, SystemType, and AuthCredential models
//  Created by Jordan Koch on 2026-05-01.
//

import XCTest
@testable import JiraSummary

final class SystemConnectionTests: XCTestCase {

    // MARK: - SystemType

    func testSystemTypeRawValues() {
        XCTAssertEqual(SystemType.jiraCloud.rawValue, "Jira Cloud")
        XCTAssertEqual(SystemType.jiraServer.rawValue, "Jira Server")
        XCTAssertEqual(SystemType.azureDevOps.rawValue, "Azure DevOps")
    }

    func testSystemTypeIcons() {
        XCTAssertEqual(SystemType.jiraCloud.icon, "cloud.fill")
        XCTAssertEqual(SystemType.jiraServer.icon, "server.rack")
        XCTAssertEqual(SystemType.azureDevOps.icon, "square.grid.3x3.fill")
    }

    func testSystemTypeLoginPaths() {
        XCTAssertEqual(SystemType.jiraCloud.loginPath, "/login")
        XCTAssertEqual(SystemType.jiraServer.loginPath, "/login.jsp")
        XCTAssertEqual(SystemType.azureDevOps.loginPath, "/_signin")
    }

    func testSystemTypeAllCases() {
        XCTAssertEqual(SystemType.allCases.count, 3)
    }

    func testSystemTypeCodable() throws {
        for type in SystemType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(SystemType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    func testSystemTypeIdentifiable() {
        XCTAssertEqual(SystemType.jiraCloud.id, "Jira Cloud")
    }

    // MARK: - SystemConnection Init

    func testSystemConnectionInit() {
        let url = URL(string: "https://company.atlassian.net")!
        let connection = SystemConnection(name: "Production Jira", type: .jiraCloud, baseURL: url)

        XCTAssertEqual(connection.name, "Production Jira")
        XCTAssertEqual(connection.type, .jiraCloud)
        XCTAssertEqual(connection.baseURL, url)
        XCTAssertFalse(connection.isAuthenticated)
        XCTAssertNil(connection.lastAuthDate)
        XCTAssertTrue(connection.boardIds.isEmpty)
    }

    func testSystemConnectionWithBoardIds() {
        let url = URL(string: "https://jira.company.com")!
        let connection = SystemConnection(name: "Server", type: .jiraServer, baseURL: url, boardIds: ["10", "20", "30"])

        XCTAssertEqual(connection.boardIds.count, 3)
        XCTAssertEqual(connection.boardIds, ["10", "20", "30"])
    }

    func testSystemConnectionCodableRoundTrip() throws {
        let url = URL(string: "https://dev.azure.com/myorg")!
        var connection = SystemConnection(name: "Azure", type: .azureDevOps, baseURL: url, boardIds: ["5"])
        connection.isAuthenticated = true
        connection.lastAuthDate = Date()

        let data = try JSONEncoder().encode(connection)
        let decoded = try JSONDecoder().decode(SystemConnection.self, from: data)

        XCTAssertEqual(decoded.id, connection.id)
        XCTAssertEqual(decoded.name, "Azure")
        XCTAssertEqual(decoded.type, .azureDevOps)
        XCTAssertEqual(decoded.baseURL, url)
        XCTAssertTrue(decoded.isAuthenticated)
        XCTAssertNotNil(decoded.lastAuthDate)
        XCTAssertEqual(decoded.boardIds, ["5"])
    }

    func testSystemConnectionHashable() {
        let url = URL(string: "https://example.com")!
        let conn = SystemConnection(name: "Test", type: .jiraCloud, baseURL: url)
        var set = Set<SystemConnection>()
        set.insert(conn)
        set.insert(conn)

        XCTAssertEqual(set.count, 1)
    }

    // MARK: - AuthCredentialType

    func testAuthCredentialTypeRawValues() {
        XCTAssertEqual(AuthCredentialType.cookie.rawValue, "cookie")
        XCTAssertEqual(AuthCredentialType.bearerToken.rawValue, "bearerToken")
        XCTAssertEqual(AuthCredentialType.basicAuth.rawValue, "basicAuth")
    }

    // MARK: - AuthCredential

    func testAuthCredentialCodable() throws {
        let credential = AuthCredential(
            systemId: UUID(),
            type: .cookie,
            value: "abc123sessiontoken",
            cookieName: "cloud.session.token",
            expiresAt: Date().addingTimeInterval(3600)
        )

        let data = try JSONEncoder().encode(credential)
        let decoded = try JSONDecoder().decode(AuthCredential.self, from: data)

        XCTAssertEqual(decoded.systemId, credential.systemId)
        XCTAssertEqual(decoded.type, .cookie)
        XCTAssertEqual(decoded.value, "abc123sessiontoken")
        XCTAssertEqual(decoded.cookieName, "cloud.session.token")
        XCTAssertNotNil(decoded.expiresAt)
    }

    func testAuthCredentialBearerToken() throws {
        let credential = AuthCredential(
            systemId: UUID(),
            type: .bearerToken,
            value: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test",
            cookieName: nil,
            expiresAt: nil
        )

        let data = try JSONEncoder().encode(credential)
        let decoded = try JSONDecoder().decode(AuthCredential.self, from: data)

        XCTAssertEqual(decoded.type, .bearerToken)
        XCTAssertNil(decoded.cookieName)
        XCTAssertNil(decoded.expiresAt)
    }

    func testAuthCredentialBasicAuth() throws {
        let credential = AuthCredential(
            systemId: UUID(),
            type: .basicAuth,
            value: "dXNlcjpwYXNz",  // base64 of user:pass
            cookieName: nil,
            expiresAt: nil
        )

        let data = try JSONEncoder().encode(credential)
        let decoded = try JSONDecoder().decode(AuthCredential.self, from: data)

        XCTAssertEqual(decoded.type, .basicAuth)
        XCTAssertEqual(decoded.value, "dXNlcjpwYXNz")
    }
}
