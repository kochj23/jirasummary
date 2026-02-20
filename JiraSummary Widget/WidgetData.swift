//
//  WidgetData.swift
//  JiraSummary Widget
//
//  Data models for the JiraSummary widget
//  Created by Jordan Koch on 2026-02-19.
//  Copyright (c) 2026 Jordan Koch. All rights reserved.
//

import Foundation
import WidgetKit

// MARK: - Widget Data

struct JiraSummaryWidgetData: Codable {
    var systemsConnected: Int = 0
    var systemsTotal: Int = 0
    var trackedPeople: Int = 0

    // Ticket aggregate stats
    var totalTickets: Int = 0
    var ticketsCompleted: Int = 0
    var ticketsInProgress: Int = 0
    var ticketsBlocked: Int = 0
    var ticketsCreated: Int = 0

    // Sprint velocity
    var avgVelocity: Double = 0
    var activeSprint: String?

    // AI backend
    var aiBackendName: String?
    var aiBackendConnected: Bool = false

    // Timestamps
    var lastRefreshDate: Date?
    var lastUpdated: Date = Date()

    // Top person summary (for medium/large)
    var topPersonName: String?
    var topPersonTickets: Int = 0
    var topPersonCompleted: Int = 0

    static let placeholder = JiraSummaryWidgetData(
        systemsConnected: 2,
        systemsTotal: 3,
        trackedPeople: 5,
        totalTickets: 42,
        ticketsCompleted: 18,
        ticketsInProgress: 15,
        ticketsBlocked: 3,
        ticketsCreated: 6,
        avgVelocity: 72.5,
        activeSprint: "Sprint 14",
        aiBackendName: "Ollama",
        aiBackendConnected: true,
        lastRefreshDate: Date(),
        topPersonName: "Alice",
        topPersonTickets: 12,
        topPersonCompleted: 7
    )
}

// MARK: - Widget Entry

struct JiraSummaryWidgetEntry: TimelineEntry {
    let date: Date
    let data: JiraSummaryWidgetData

    static let placeholder = JiraSummaryWidgetEntry(
        date: Date(),
        data: .placeholder
    )
}

// MARK: - Helpers

extension JiraSummaryWidgetData {
    var healthColorName: String {
        if systemsTotal == 0 { return "gray" }
        let ratio = Double(systemsConnected) / Double(systemsTotal)
        if ratio >= 1.0 { return "green" }
        if ratio >= 0.5 { return "yellow" }
        if ratio > 0 { return "orange" }
        return "red"
    }

    var completionRate: Double {
        guard totalTickets > 0 else { return 0 }
        return Double(ticketsCompleted) / Double(totalTickets) * 100
    }

    var velocityLabel: String {
        String(format: "%.0f%%", avgVelocity)
    }
}

extension Date {
    var widgetRelativeString: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}
