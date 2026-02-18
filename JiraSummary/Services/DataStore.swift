//
//  DataStore.swift
//  JiraSummary
//
//  JSON persistence for connections, tracked people, and cached data
//  Stores in ~/Library/Application Support/JiraSummary/
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation
import Observation

@Observable
@MainActor
final class DataStore {
    static let shared = DataStore()

    var connections: [SystemConnection] = []
    var trackedPeople: [TrackedPerson] = []
    var ticketActivities: [TicketActivity] = []
    var sprintData: [SprintData] = []
    var personSummaries: [PersonSummary] = []

    var isLoading = false
    var lastRefreshDate: Date?

    private let fileManager = FileManager.default
    private let appSupportDir: URL

    private init() {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        appSupportDir = paths[0].appendingPathComponent("JiraSummary", isDirectory: true)

        if !fileManager.fileExists(atPath: appSupportDir.path) {
            try? fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        }

        loadAll()
    }

    // MARK: - Connections

    func addConnection(_ connection: SystemConnection) {
        connections.append(connection)
        saveConnections()
    }

    func updateConnection(_ connection: SystemConnection) {
        if let index = connections.firstIndex(where: { $0.id == connection.id }) {
            connections[index] = connection
            saveConnections()
        }
    }

    func removeConnection(_ connectionId: UUID) {
        connections.removeAll { $0.id == connectionId }
        trackedPeople.removeAll { $0.systemId == connectionId }
        ticketActivities.removeAll { $0.systemId == connectionId }
        sprintData.removeAll { $0.systemId == connectionId }
        personSummaries.removeAll { $0.systemId == connectionId }
        saveAll()
    }

    // MARK: - Tracked People

    func addPerson(_ person: TrackedPerson) {
        trackedPeople.append(person)
        savePeople()
    }

    func removePerson(_ personId: UUID) {
        trackedPeople.removeAll { $0.id == personId }
        ticketActivities.removeAll { $0.personId == personId }
        personSummaries.removeAll { $0.personId == personId }
        savePeople()
        saveTicketActivities()
        saveSummaries()
    }

    func people(for systemId: UUID) -> [TrackedPerson] {
        trackedPeople.filter { $0.systemId == systemId }
    }

    // MARK: - Ticket Activities

    func updateTicketActivities(_ activities: [TicketActivity], for personId: UUID, systemId: UUID) {
        ticketActivities.removeAll { $0.personId == personId && $0.systemId == systemId }
        ticketActivities.append(contentsOf: activities)
        saveTicketActivities()
    }

    func activities(for personId: UUID) -> [TicketActivity] {
        ticketActivities.filter { $0.personId == personId }
    }

    // MARK: - Sprint Data

    func updateSprintData(_ sprints: [SprintData], for systemId: UUID) {
        sprintData.removeAll { $0.systemId == systemId }
        sprintData.append(contentsOf: sprints)
        saveSprintData()
    }

    func sprints(for systemId: UUID) -> [SprintData] {
        sprintData.filter { $0.systemId == systemId }
    }

    // MARK: - Summaries

    func updateSummary(_ summary: PersonSummary) {
        if let index = personSummaries.firstIndex(where: { $0.personId == summary.personId && $0.systemId == summary.systemId && $0.period == summary.period }) {
            personSummaries[index] = summary
        } else {
            personSummaries.append(summary)
        }
        saveSummaries()
    }

    func summary(for personId: UUID, systemId: UUID, period: SummaryPeriod) -> PersonSummary? {
        personSummaries.first { $0.personId == personId && $0.systemId == systemId && $0.period == period }
    }

    // MARK: - Persistence

    private func loadAll() {
        connections = load("connections.json") ?? []
        trackedPeople = load("people.json") ?? []
        ticketActivities = load("activities.json") ?? []
        sprintData = load("sprints.json") ?? []
        personSummaries = load("summaries.json") ?? []

        if let dateData = try? Data(contentsOf: appSupportDir.appendingPathComponent("last_refresh.json")),
           let date = try? JSONDecoder().decode(Date.self, from: dateData) {
            lastRefreshDate = date
        }
    }

    func saveAll() {
        saveConnections()
        savePeople()
        saveTicketActivities()
        saveSprintData()
        saveSummaries()
    }

    private func saveConnections() { save(connections, to: "connections.json") }
    private func savePeople() { save(trackedPeople, to: "people.json") }
    private func saveTicketActivities() { save(ticketActivities, to: "activities.json") }
    private func saveSprintData() { save(sprintData, to: "sprints.json") }
    private func saveSummaries() { save(personSummaries, to: "summaries.json") }

    func saveLastRefreshDate() {
        lastRefreshDate = Date()
        if let data = try? JSONEncoder().encode(lastRefreshDate) {
            try? data.write(to: appSupportDir.appendingPathComponent("last_refresh.json"))
        }
    }

    private func load<T: Decodable>(_ filename: String) -> T? {
        let url = appSupportDir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ object: T, to filename: String) {
        let url = appSupportDir.appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(object) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
