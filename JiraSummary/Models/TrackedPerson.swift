//
//  TrackedPerson.swift
//  JiraSummary
//
//  Represents a person tracked within a specific system
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

struct TrackedPerson: Codable, Identifiable, Hashable {
    let id: UUID
    let systemId: UUID
    var displayName: String
    var systemUserId: String
    var emailAddress: String?
    var avatarURL: URL?
    var dateAdded: Date

    init(systemId: UUID, displayName: String, systemUserId: String, emailAddress: String? = nil, avatarURL: URL? = nil) {
        self.id = UUID()
        self.systemId = systemId
        self.displayName = displayName
        self.systemUserId = systemUserId
        self.emailAddress = emailAddress
        self.avatarURL = avatarURL
        self.dateAdded = Date()
    }
}
