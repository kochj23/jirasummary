//
//  WidgetDataSync.swift
//  JiraSummary
//
//  Syncs main app state to the widget via shared Application Support directory.
//  Created by Jordan Koch on 2026-02-19.
//  Copyright (c) 2026 Jordan Koch. All rights reserved.
//

import Foundation
import WidgetKit

/// Syncs main app state to the widget via shared Application Support directory.
class WidgetDataSyncService {
    static let shared = WidgetDataSyncService()

    private let dataFileName = "widget_data.json"
    private let appSupportFolder = "JiraSummary"
    private let appGroupIdentifier = "group.com.jordankoch.jirasummary"

    private var containerURL: URL? {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return groupURL
        }
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent(appSupportFolder, isDirectory: true)
    }

    private var dataFileURL: URL? {
        containerURL?.appendingPathComponent(dataFileName)
    }

    private init() {}

    /// Update widget data from current DataStore state
    @MainActor
    func syncFromDataStore() {
        let dataStore = DataStore.shared

        var data = WidgetData()

        // System connections
        let authenticatedSystems = dataStore.connections.filter { $0.isAuthenticated }
        data.systemsConnected = authenticatedSystems.count
        data.systemsTotal = dataStore.connections.count
        data.trackedPeople = dataStore.trackedPeople.count

        // Aggregate ticket stats from latest weekly summaries
        let weeklySummaries = dataStore.personSummaries.filter { $0.period == .weekly }
        data.totalTickets = weeklySummaries.reduce(0) { $0 + $1.totalTickets }
        data.ticketsCompleted = weeklySummaries.reduce(0) { $0 + $1.ticketsCompleted }
        data.ticketsInProgress = weeklySummaries.reduce(0) { $0 + $1.ticketsInProgress }
        data.ticketsBlocked = weeklySummaries.reduce(0) { $0 + $1.ticketsBlocked }
        data.ticketsCreated = weeklySummaries.reduce(0) { $0 + $1.ticketsCreated }

        // Sprint velocity
        if !weeklySummaries.isEmpty {
            data.avgVelocity = weeklySummaries.map { $0.velocityPercentage }.reduce(0, +) / Double(weeklySummaries.count)
        }

        // Active sprint
        if let activeSprint = dataStore.sprintData.first(where: { $0.state == .active }) {
            data.activeSprint = activeSprint.sprintName
        }

        // Top contributor
        if let topPerson = weeklySummaries.max(by: { $0.ticketsCompleted < $1.ticketsCompleted }) {
            data.topPersonName = topPerson.personName
            data.topPersonTickets = topPerson.totalTickets
            data.topPersonCompleted = topPerson.ticketsCompleted
        }

        // Timestamps
        data.lastRefreshDate = dataStore.lastRefreshDate
        data.lastUpdated = Date()

        saveWidgetData(data)
    }

    private func saveWidgetData(_ widgetData: WidgetData) {
        guard let url = dataFileURL else { return }
        if let containerURL = containerURL {
            try? FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(widgetData)
            try data.write(to: url, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("[WidgetSync] Failed to save widget data: \(error)")
        }
    }

    /// Private Codable struct matching the widget's data model
    private struct WidgetData: Codable {
        var systemsConnected: Int = 0
        var systemsTotal: Int = 0
        var trackedPeople: Int = 0
        var totalTickets: Int = 0
        var ticketsCompleted: Int = 0
        var ticketsInProgress: Int = 0
        var ticketsBlocked: Int = 0
        var ticketsCreated: Int = 0
        var avgVelocity: Double = 0
        var activeSprint: String?
        var aiBackendName: String?
        var aiBackendConnected: Bool = false
        var lastRefreshDate: Date?
        var lastUpdated: Date = Date()
        var topPersonName: String?
        var topPersonTickets: Int = 0
        var topPersonCompleted: Int = 0
    }
}
