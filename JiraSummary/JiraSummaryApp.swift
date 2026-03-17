//
//  JiraSummaryApp.swift
//  JiraSummary
//
//  Main app entry point with AppDelegate for dark mode enforcement
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

@main
struct JiraSummaryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        NovaAPIServer.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1100, minHeight: 700)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1400, height: 900)

        Settings {
            SettingsView()
                .frame(minWidth: 500, minHeight: 400)
                .preferredColorScheme(.dark)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc func refreshData() {
        Task { @MainActor in
            await DataFetchCoordinator.shared.fetchAll()
        }
    }
}
