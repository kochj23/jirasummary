//
//  SprintData.swift
//  JiraSummary
//
//  Sprint/iteration velocity data
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation

struct SprintData: Codable, Identifiable, Hashable {
    let id: UUID
    let systemId: UUID
    var sprintName: String
    var boardName: String?
    var startDate: Date?
    var endDate: Date?
    var state: SprintState
    var committedPoints: Double
    var completedPoints: Double
    var carryOverPoints: Double
    var totalIssues: Int
    var completedIssues: Int
    var goal: String?
    var personBreakdowns: [PersonSprintBreakdown]

    init(systemId: UUID, sprintName: String, state: SprintState = .active) {
        self.id = UUID()
        self.systemId = systemId
        self.sprintName = sprintName
        self.state = state
        self.committedPoints = 0
        self.completedPoints = 0
        self.carryOverPoints = 0
        self.totalIssues = 0
        self.completedIssues = 0
        self.personBreakdowns = []
    }

    var velocityPercentage: Double {
        guard committedPoints > 0 else { return 0 }
        return (completedPoints / committedPoints) * 100
    }
}

enum SprintState: String, Codable {
    case future
    case active
    case closed
}

struct PersonSprintBreakdown: Codable, Identifiable, Hashable {
    let id: UUID
    let personId: UUID
    var personName: String
    var committedPoints: Double
    var completedPoints: Double
    var issuesCompleted: Int
    var issuesTotal: Int

    init(personId: UUID, personName: String) {
        self.id = UUID()
        self.personId = personId
        self.personName = personName
        self.committedPoints = 0
        self.completedPoints = 0
        self.issuesCompleted = 0
        self.issuesTotal = 0
    }
}
