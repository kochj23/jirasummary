//
//  MenuBarManager.swift
//  JiraSummary
//
//  Menu bar status item with quick summary access
//  Created by Jordan Koch on 2026-02-17.
//

import AppKit
import SwiftUI

@MainActor
@Observable
final class MenuBarManager {
    static let shared = MenuBarManager()

    var isEnabled = false {
        didSet {
            if isEnabled { setupStatusItem() }
            else { removeStatusItem() }
        }
    }

    private var statusItem: NSStatusItem?

    private init() {}

    func setupStatusItem() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "chart.bar.doc.horizontal", accessibilityDescription: "Jira Summary")
            button.action = #selector(AppDelegate.showMainWindow)
            button.target = NSApp.delegate as? AppDelegate
        }

        updateMenu()
    }

    func removeStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    func updateMenu() {
        let menu = NSMenu()

        let dataStore = DataStore.shared
        let coordinator = DataFetchCoordinator.shared

        // Status
        if coordinator.isFetching {
            menu.addItem(NSMenuItem(title: "Refreshing...", action: nil, keyEquivalent: ""))
        } else if let lastRefresh = dataStore.lastRefreshDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let relative = formatter.localizedString(for: lastRefresh, relativeTo: Date())
            menu.addItem(NSMenuItem(title: "Last updated: \(relative)", action: nil, keyEquivalent: ""))
        }

        menu.addItem(.separator())

        // Quick summary counts
        let summaries = dataStore.personSummaries
        if summaries.isEmpty {
            menu.addItem(NSMenuItem(title: "No data yet", action: nil, keyEquivalent: ""))
        } else {
            let totalCompleted = summaries.reduce(0) { $0 + $1.ticketsCompleted }
            let totalInProgress = summaries.reduce(0) { $0 + $1.ticketsInProgress }
            let totalBlocked = summaries.reduce(0) { $0 + $1.ticketsBlocked }

            menu.addItem(NSMenuItem(title: "Completed: \(totalCompleted)", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "In Progress: \(totalInProgress)", action: nil, keyEquivalent: ""))
            if totalBlocked > 0 {
                menu.addItem(NSMenuItem(title: "Blocked: \(totalBlocked)", action: nil, keyEquivalent: ""))
            }
        }

        menu.addItem(.separator())

        // Actions
        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(AppDelegate.refreshData), keyEquivalent: "r")
        refreshItem.target = NSApp.delegate as? AppDelegate
        menu.addItem(refreshItem)

        let openItem = NSMenuItem(title: "Open JiraSummary", action: #selector(AppDelegate.showMainWindow), keyEquivalent: "o")
        openItem.target = NSApp.delegate as? AppDelegate
        menu.addItem(openItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }
}
