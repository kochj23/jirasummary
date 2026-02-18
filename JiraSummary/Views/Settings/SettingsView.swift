//
//  SettingsView.swift
//  JiraSummary
//
//  Configuration for refresh interval, AI, and menu bar
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct SettingsView: View {
    @State private var refreshInterval: Double = 30
    @State private var enableMenuBar = false
    @State private var enableAI = false
    @State private var ollamaEndpoint = "http://localhost:11434"
    @State private var ollamaModel = "llama3"
    @State private var defaultPeriod: SummaryPeriod = .weekly
    @State private var ollamaAvailable: Bool?
    @State private var isCheckingOllama = false

    private let menuBarManager = MenuBarManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .modernHeader(size: .large)

                // General
                settingsSection("General") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Refresh interval
                        HStack {
                            Text("Auto-refresh interval")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(ModernColors.textPrimary)
                            Spacer()
                            Picker("Interval", selection: $refreshInterval) {
                                Text("15 min").tag(15.0)
                                Text("30 min").tag(30.0)
                                Text("1 hour").tag(60.0)
                                Text("2 hours").tag(120.0)
                                Text("Manual only").tag(0.0)
                            }
                            .frame(width: 160)
                        }

                        // Default period
                        HStack {
                            Text("Default summary period")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(ModernColors.textPrimary)
                            Spacer()
                            Picker("Period", selection: $defaultPeriod) {
                                ForEach(SummaryPeriod.allCases, id: \.self) { period in
                                    Text(period.rawValue).tag(period)
                                }
                            }
                            .frame(width: 160)
                        }
                    }
                }

                // Menu Bar
                settingsSection("Menu Bar") {
                    Toggle(isOn: $enableMenuBar) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show in menu bar")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(ModernColors.textPrimary)

                            Text("Quick access to summary stats from the menu bar")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(ModernColors.textTertiary)
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: enableMenuBar) { _, newValue in
                        menuBarManager.isEnabled = newValue
                    }
                }

                // AI Summaries
                settingsSection("AI Summaries (Ollama)") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $enableAI) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable AI summaries")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(ModernColors.textPrimary)

                                Text("Uses local Ollama LLM — your data never leaves this machine")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(ModernColors.textTertiary)
                            }
                        }
                        .toggleStyle(.switch)

                        if enableAI {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Endpoint")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(ModernColors.textSecondary)
                                        .frame(width: 80, alignment: .trailing)
                                    TextField("http://localhost:11434", text: $ollamaEndpoint)
                                        .textFieldStyle(.roundedBorder)
                                }

                                HStack {
                                    Text("Model")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(ModernColors.textSecondary)
                                        .frame(width: 80, alignment: .trailing)
                                    TextField("llama3", text: $ollamaModel)
                                        .textFieldStyle(.roundedBorder)
                                }

                                HStack {
                                    Button {
                                        testOllama()
                                    } label: {
                                        HStack(spacing: 6) {
                                            if isCheckingOllama {
                                                ProgressView().scaleEffect(0.7)
                                            } else {
                                                Image(systemName: "bolt.fill")
                                            }
                                            Text("Test Connection")
                                        }
                                    }
                                    .buttonStyle(ModernButtonStyle(color: ModernColors.purple, style: .outlined))

                                    if let available = ollamaAvailable {
                                        HStack(spacing: 4) {
                                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(available ? ModernColors.accentGreen : ModernColors.accentRed)
                                            Text(available ? "Ollama is running" : "Ollama not found")
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundColor(available ? ModernColors.accentGreen : ModernColors.accentRed)
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 16)
                        }
                    }
                }

                // About
                settingsSection("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("JiraSummary v1.0.0")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)

                        Text("Track team activity across Jira and Azure DevOps")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)

                        Text("Created by Jordan Koch")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                }
            }
            .padding(24)
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)

            content()
                .padding(16)
                .compactGlassCard()
        }
    }

    private func testOllama() {
        isCheckingOllama = true
        ollamaAvailable = nil

        Task {
            guard let url = URL(string: ollamaEndpoint) else {
                ollamaAvailable = false
                isCheckingOllama = false
                return
            }

            let service = AISummaryService.shared
            await service.configure(endpoint: url, model: ollamaModel)
            let available = await service.checkAvailability()

            ollamaAvailable = available
            isCheckingOllama = false
        }
    }
}
