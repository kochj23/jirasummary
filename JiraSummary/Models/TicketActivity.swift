//
//  TicketActivity.swift
//  JiraSummary
//
//  Represents individual ticket/work item activity and status transitions
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

struct TicketActivity: Codable, Identifiable, Hashable {
    let id: UUID
    let systemId: UUID
    let personId: UUID
    var ticketKey: String
    var title: String
    var currentStatus: String
    var priority: String?
    var ticketType: String?
    var storyPoints: Double?
    var transitions: [StatusTransition]
    var createdDate: Date
    var updatedDate: Date
    var resolvedDate: Date?
    var ticketURL: URL?
    var sprintName: String?

    init(systemId: UUID, personId: UUID, ticketKey: String, title: String, currentStatus: String) {
        self.id = UUID()
        self.systemId = systemId
        self.personId = personId
        self.ticketKey = ticketKey
        self.title = title
        self.currentStatus = currentStatus
        self.transitions = []
        self.createdDate = Date()
        self.updatedDate = Date()
    }
}

struct StatusTransition: Codable, Hashable {
    let fromStatus: String?
    let toStatus: String
    let transitionDate: Date
    let author: String?
}
