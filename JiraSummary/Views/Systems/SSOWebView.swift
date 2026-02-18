//
//  SSOWebView.swift
//  JiraSummary
//
//  WKWebView wrapper for SSO authentication
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI
import WebKit

struct SSOWebView: View {
    @Environment(\.dismiss) private var dismiss
    let connection: SystemConnection

    @StateObject private var authService = SSOAuthService()
    @State private var dataStore = DataStore.shared
    @State private var authComplete = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Authenticate: \(connection.name)")
                        .modernHeader(size: .medium)

                    Text("Sign in with your corporate SSO to connect")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                }

                Spacer()

                if authComplete {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ModernColors.accentGreen)
                        Text("Authenticated!")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.accentGreen)
                    }
                }

                Button("Cancel") {
                    authService.cancelAuth()
                    dismiss()
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.textTertiary, style: .outlined))
            }
            .padding(16)

            Divider().background(ModernColors.glassBorder)

            // Error banner
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(ModernColors.accentOrange)
                    Text(error)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(ModernColors.accentOrange)
                    Spacer()
                }
                .padding(12)
                .background(ModernColors.accentOrange.opacity(0.1))
            }

            // WebView
            WebViewRepresentable(
                connection: connection,
                authService: authService,
                onAuthenticated: { credential in
                    handleAuth(credential: credential)
                },
                onError: { error in
                    errorMessage = error
                }
            )
        }
        .background(.ultraThickMaterial)
    }

    private func handleAuth(credential: AuthCredential) {
        do {
            try KeychainService.shared.storeCredential(credential)
            var updated = connection
            updated.isAuthenticated = true
            updated.lastAuthDate = Date()
            dataStore.updateConnection(updated)
            authComplete = true

            // Auto-dismiss after success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            errorMessage = "Failed to store credentials: \(error.localizedDescription)"
        }
    }
}

// MARK: - WebView Representable

struct WebViewRepresentable: NSViewRepresentable {
    let connection: SystemConnection
    let authService: SSOAuthService
    let onAuthenticated: (AuthCredential) -> Void
    let onError: (String) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true

        Task { @MainActor in
            do {
                let credential = try await authService.authenticate(
                    systemId: connection.id,
                    baseURL: connection.baseURL,
                    type: connection.type,
                    webView: webView
                )
                onAuthenticated(credential)
            } catch let error as SSOAuthError where error == .cancelled {
                // User cancelled, no error
            } catch {
                onError(error.localizedDescription)
            }
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
