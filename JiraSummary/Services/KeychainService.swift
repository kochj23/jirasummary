//
//  KeychainService.swift
//  JiraSummary
//
//  Secure credential storage in macOS Keychain
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let serviceName = "com.jordankoch.JiraSummary"

    private init() {}

    // MARK: - Store Credential

    func storeCredential(_ credential: AuthCredential) throws {
        let key = credentialKey(for: credential.systemId)
        let data = try JSONEncoder().encode(credential)

        // Delete existing entry
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new entry
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }

    // MARK: - Retrieve Credential

    func retrieveCredential(for systemId: UUID) -> AuthCredential? {
        let key = credentialKey(for: systemId)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let credential = try? JSONDecoder().decode(AuthCredential.self, from: data) else {
            return nil
        }

        return credential
    }

    // MARK: - Delete Credential

    func deleteCredential(for systemId: UUID) {
        let key = credentialKey(for: systemId)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Check if Credential Exists

    func hasCredential(for systemId: UUID) -> Bool {
        retrieveCredential(for: systemId) != nil
    }

    // MARK: - Private Helpers

    private func credentialKey(for systemId: UUID) -> String {
        "auth_\(systemId.uuidString)"
    }
}

enum KeychainError: LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store credential in Keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve credential from Keychain (status: \(status))"
        }
    }
}
