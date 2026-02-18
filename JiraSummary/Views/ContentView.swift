//
//  ContentView.swift
//  JiraSummary
//
//  Main NavigationSplitView with sidebar navigation
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedNav: NavItem? = .dashboard
    @State private var dataStore = DataStore.shared
    @State private var coordinator = DataFetchCoordinator.shared

    var body: some View {
        ZStack {
            GlassmorphicBackground()

            NavigationSplitView {
                SidebarView(selection: $selectedNav)
                    .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
            } detail: {
                Group {
                    switch selectedNav {
                    case .dashboard:
                        DashboardView()
                    case .systems:
                        SystemsListView()
                    case .people:
                        PeopleListView()
                    case .settings:
                        SettingsView()
                    case .none:
                        DashboardView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            // Auto-refresh on launch if stale (> 30 min)
            if let last = dataStore.lastRefreshDate,
               Date().timeIntervalSince(last) > 1800,
               !dataStore.connections.filter({ $0.isAuthenticated }).isEmpty {
                await coordinator.fetchAll()
            }
        }
    }
}

enum NavItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case systems = "Systems"
    case people = "People"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.xaxis"
        case .systems: return "server.rack"
        case .people: return "person.2.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
