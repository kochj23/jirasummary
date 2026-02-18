//
//  SSOAuthService.swift
//  JiraSummary
//
//  WKWebView SSO authentication flow manager
//  Captures session cookies/tokens after user completes SSO login
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation
import WebKit

@MainActor
final class SSOAuthService: NSObject, ObservableObject {
    @Published var isAuthenticating = false
    @Published var authError: String?

    private var authContinuation: CheckedContinuation<AuthCredential, Error>?
    private var targetURL: URL?
    private var systemType: SystemType?
    private var systemId: UUID?

    // MARK: - Authenticate

    func authenticate(systemId: UUID, baseURL: URL, type: SystemType, webView: WKWebView) async throws -> AuthCredential {
        self.targetURL = baseURL
        self.systemType = type
        self.systemId = systemId
        self.isAuthenticating = true
        self.authError = nil

        webView.navigationDelegate = self

        let loginURL: URL
        switch type {
        case .jiraCloud:
            loginURL = baseURL.appendingPathComponent("/login")
        case .jiraServer:
            loginURL = baseURL.appendingPathComponent("/login.jsp")
        case .azureDevOps:
            loginURL = baseURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            webView.load(URLRequest(url: loginURL))
        }
    }

    // MARK: - Cookie Extraction

    private func extractCredentials(from webView: WKWebView) {
        guard let systemType = systemType, let systemId = systemId else { return }

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            Task { @MainActor in
                guard let self = self else { return }

                var credential: AuthCredential?

                switch systemType {
                case .jiraCloud:
                    // Look for cloud.session.token or atlassian.xsrf.token
                    if let sessionCookie = cookies.first(where: { $0.name == "cloud.session.token" }) {
                        credential = AuthCredential(
                            systemId: systemId,
                            type: .cookie,
                            value: sessionCookie.value,
                            cookieName: sessionCookie.name,
                            expiresAt: sessionCookie.expiresDate
                        )
                    } else if let tenantCookie = cookies.first(where: { $0.name.contains("tenant.session") }) {
                        credential = AuthCredential(
                            systemId: systemId,
                            type: .cookie,
                            value: tenantCookie.value,
                            cookieName: tenantCookie.name,
                            expiresAt: tenantCookie.expiresDate
                        )
                    }

                case .jiraServer:
                    // Look for JSESSIONID
                    if let sessionCookie = cookies.first(where: { $0.name == "JSESSIONID" }) {
                        credential = AuthCredential(
                            systemId: systemId,
                            type: .cookie,
                            value: sessionCookie.value,
                            cookieName: sessionCookie.name,
                            expiresAt: sessionCookie.expiresDate
                        )
                    }

                case .azureDevOps:
                    // Look for bearer token cookies or FedAuth
                    if let authCookie = cookies.first(where: { $0.name.contains("FedAuth") || $0.name.contains("AadAuth") }) {
                        credential = AuthCredential(
                            systemId: systemId,
                            type: .cookie,
                            value: authCookie.value,
                            cookieName: authCookie.name,
                            expiresAt: authCookie.expiresDate
                        )
                    }
                }

                if let credential = credential {
                    self.isAuthenticating = false
                    self.authContinuation?.resume(returning: credential)
                    self.authContinuation = nil
                }
            }
        }
    }

    func cancelAuth() {
        isAuthenticating = false
        authContinuation?.resume(throwing: SSOAuthError.cancelled)
        authContinuation = nil
    }
}

// MARK: - WKNavigationDelegate

extension SSOAuthService: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            guard let url = webView.url, let targetURL = self.targetURL else { return }

            // Check if we've returned to the base application (past login)
            let isOnApp: Bool
            switch self.systemType {
            case .jiraCloud:
                isOnApp = url.path.contains("/wiki") || url.path.contains("/browse") ||
                          url.path.contains("/jira") || url.path == "/" ||
                          url.host == targetURL.host && !url.path.contains("login")
            case .jiraServer:
                isOnApp = url.host == targetURL.host && !url.path.contains("login")
            case .azureDevOps:
                isOnApp = url.host?.contains("dev.azure.com") == true ||
                          url.host?.contains("visualstudio.com") == true
            case .none:
                isOnApp = false
            }

            if isOnApp {
                self.extractCredentials(from: webView)
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.authError = error.localizedDescription
        }
    }
}

enum SSOAuthError: LocalizedError {
    case cancelled
    case noCredentialFound
    case timeout

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Authentication was cancelled"
        case .noCredentialFound: return "No session credential found after login"
        case .timeout: return "Authentication timed out"
        }
    }
}
