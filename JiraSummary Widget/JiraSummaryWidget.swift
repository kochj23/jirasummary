//
//  JiraSummaryWidget.swift
//  JiraSummary Widget
//
//  WidgetKit extension for JiraSummary — shows ticket stats, sprint velocity,
//  connected systems, and tracked people at a glance.
//  Created by Jordan Koch on 2026-02-19.
//  Copyright (c) 2026 Jordan Koch. All rights reserved.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct JiraSummaryWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> JiraSummaryWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (JiraSummaryWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            let data = SharedDataManager.shared.loadWidgetData()
            completion(JiraSummaryWidgetEntry(date: Date(), data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JiraSummaryWidgetEntry>) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = JiraSummaryWidgetEntry(date: Date(), data: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Small Widget View

struct JiraSummaryWidgetSmallView: View {
    let entry: JiraSummaryWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "ticket.fill")
                    .font(.title3)
                    .foregroundColor(.cyan)
                Text("Jira Summary")
                    .font(.caption.bold())
                Spacer()
            }

            Spacer()

            // Ticket counts
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.data.totalTickets)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Tickets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.data.ticketsCompleted)")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                    Text("Done")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Bottom stats
            HStack {
                Image(systemName: "server.rack")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(entry.data.systemsConnected)/\(entry.data.systemsTotal)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if entry.data.ticketsBlocked > 0 {
                    Image(systemName: "xmark.octagon.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("\(entry.data.ticketsBlocked)")
                        .font(.caption2.bold())
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget View

struct JiraSummaryWidgetMediumView: View {
    let entry: JiraSummaryWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left — Overview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "ticket.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    Text("Jira Summary")
                        .font(.headline)
                }

                // Systems
                HStack(spacing: 6) {
                    Circle()
                        .fill(systemHealthColor)
                        .frame(width: 8, height: 8)
                    Image(systemName: "server.rack")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(entry.data.systemsConnected)/\(entry.data.systemsTotal) systems")
                        .font(.caption)
                        .lineLimit(1)
                }

                // People
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(entry.data.trackedPeople) people tracked")
                        .font(.caption)
                        .lineLimit(1)
                }

                // AI Backend
                if let aiName = entry.data.aiBackendName {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(entry.data.aiBackendConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Image(systemName: "brain")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(aiName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }

                // Last refresh
                if let refresh = entry.data.lastRefreshDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(refresh.widgetRelativeString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Right — Ticket Stats
            VStack(alignment: .trailing, spacing: 8) {
                // Tickets overview
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Tickets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(entry.data.totalTickets)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }

                Divider()

                // Status breakdown
                HStack(spacing: 12) {
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(entry.data.ticketsCompleted)")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Text("Done")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(entry.data.ticketsInProgress)")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(entry.data.ticketsBlocked)")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                        Text("Blocked")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Velocity
                HStack(spacing: 4) {
                    Image(systemName: "gauge.medium")
                        .font(.caption2)
                        .foregroundColor(.purple)
                    Text(entry.data.velocityLabel)
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                    Text("velocity")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    private var systemHealthColor: Color {
        switch entry.data.healthColorName {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .secondary
        }
    }
}

// MARK: - Large Widget View

struct JiraSummaryWidgetLargeView: View {
    let entry: JiraSummaryWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "ticket.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
                Text("Jira Summary")
                    .font(.headline)
                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(systemHealthColor)
                        .frame(width: 8, height: 8)
                    Text("\(entry.data.systemsConnected)/\(entry.data.systemsTotal) online")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(systemHealthColor.opacity(0.15))
                .cornerRadius(8)
            }

            Divider()

            // Ticket Stats Grid
            HStack(spacing: 12) {
                ticketStatBox(title: "Total", value: "\(entry.data.totalTickets)", color: .white)
                ticketStatBox(title: "Completed", value: "\(entry.data.ticketsCompleted)", color: .green)
                ticketStatBox(title: "In Progress", value: "\(entry.data.ticketsInProgress)", color: .blue)
                ticketStatBox(title: "Blocked", value: "\(entry.data.ticketsBlocked)", color: .red)
            }

            Divider()

            // Sprint & Velocity
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sprint Velocity")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "gauge.medium")
                            .font(.title3)
                            .foregroundColor(.purple)
                        Text(entry.data.velocityLabel)
                            .font(.title3.bold())
                            .foregroundColor(.purple)
                    }

                    if let sprint = entry.data.activeSprint {
                        Text(sprint)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tracked People")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                            .foregroundColor(.cyan)
                        Text("\(entry.data.trackedPeople)")
                            .font(.title3.bold())
                            .foregroundColor(.cyan)
                    }

                    Text("\(entry.data.systemsTotal) systems")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Top Performer
            if let topName = entry.data.topPersonName {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Contributor")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(topName)
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(entry.data.topPersonCompleted)/\(entry.data.topPersonTickets) done")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                // AI Backend
                if let aiName = entry.data.aiBackendName {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(entry.data.aiBackendConnected ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Image(systemName: "brain")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(aiName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Last Refresh
                if let refresh = entry.data.lastRefreshDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Updated \(refresh.widgetRelativeString)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }

    private func ticketStatBox(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var systemHealthColor: Color {
        switch entry.data.healthColorName {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .secondary
        }
    }
}

// MARK: - Widget Entry View

struct JiraSummaryWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: JiraSummaryWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            JiraSummaryWidgetSmallView(entry: entry)
        case .systemMedium:
            JiraSummaryWidgetMediumView(entry: entry)
        case .systemLarge:
            JiraSummaryWidgetLargeView(entry: entry)
        default:
            JiraSummaryWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

@main
struct JiraSummaryWidget: Widget {
    let kind: String = "JiraSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JiraSummaryWidgetProvider()) { entry in
            JiraSummaryWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Jira Summary")
        .description("Monitor ticket activity, sprint velocity, and connected systems.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    JiraSummaryWidget()
} timeline: {
    JiraSummaryWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    JiraSummaryWidget()
} timeline: {
    JiraSummaryWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    JiraSummaryWidget()
} timeline: {
    JiraSummaryWidgetEntry.placeholder
}
