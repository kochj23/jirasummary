//
//  AIBackendStatusMenu.swift
//  JiraSummary
//
//  Reusable AI backend status bar component
//  Shows backend status, model selection, and quick settings access
//  Matches Blompie AI infrastructure pattern
//  Created by Jordan Koch on 2026-02-17.
//

import SwiftUI

struct AIBackendStatusMenu: View {
    var manager = AIBackendManager.shared
    @State private var isRefreshing = false

    var accentColor: Color = ModernColors.purple
    var compact: Bool = false
    var showModelPicker: Bool = true

    var body: some View {
        HStack(spacing: compact ? 8 : 12) {
            statusIndicator
            if !compact { backendSelector }
            if showModelPicker && manager.activeBackend == .ollama && !manager.ollamaModels.isEmpty {
                modelSelector
            }
            actionButtons
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 8)
        .compactGlassCard()
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 2)
                        .scaleEffect(isRefreshing ? 1.5 : 1.0)
                        .opacity(isRefreshing ? 0 : 1)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: isRefreshing)
                )

            if !compact {
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(statusColor)

                    Text(manager.activeBackend.rawValue)
                        .font(.system(size: 9, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
            }
        }
    }

    private var statusColor: Color {
        if manager.isAvailable(manager.activeBackend) {
            return ModernColors.accentGreen
        } else if manager.anyBackendAvailable {
            return .orange
        } else {
            return ModernColors.accentRed
        }
    }

    private var statusText: String {
        if manager.isAvailable(manager.activeBackend) {
            return "Connected"
        } else if manager.anyBackendAvailable {
            return "Fallback Available"
        } else {
            return "Offline"
        }
    }

    // MARK: - Backend Selector

    private var backendSelector: some View {
        Menu {
            ForEach(AIBackend.allCases) { backend in
                Button {
                    manager.activeBackend = backend
                    manager.saveConfiguration()
                    Task { await manager.refreshAllBackends() }
                } label: {
                    HStack {
                        Image(systemName: backend.icon)
                        Text(backend.rawValue)
                        Spacer()
                        if manager.isAvailable(backend) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        if manager.activeBackend == backend {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: manager.activeBackend.icon)
                Text("Backend")
                    .font(.system(size: 11, design: .rounded))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .foregroundColor(accentColor)
        }
        .menuStyle(.borderlessButton)
        .frame(height: 24)
    }

    // MARK: - Model Selector

    private var modelSelector: some View {
        Menu {
            ForEach(manager.ollamaModels, id: \.self) { model in
                Button {
                    manager.selectedOllamaModel = model
                    manager.saveConfiguration()
                } label: {
                    HStack {
                        Text(model)
                        Spacer()
                        if manager.selectedOllamaModel == model {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "brain")
                Text(truncateModelName(manager.selectedOllamaModel))
                    .font(.system(size: 11, design: .rounded))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .foregroundColor(accentColor)
        }
        .menuStyle(.borderlessButton)
        .frame(height: 24)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 4) {
            Button {
                isRefreshing = true
                Task {
                    await manager.refreshAllBackends()
                    try? await Task.sleep(for: .milliseconds(500))
                    isRefreshing = false
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundColor(accentColor)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRefreshing)
            }
            .buttonStyle(.plain)
            .help("Refresh backend status")
        }
    }

    private func truncateModelName(_ name: String) -> String {
        let parts = name.split(separator: ":")
        return String(parts.first ?? Substring(name))
    }
}

struct AIBackendStatusMenuCompact: View {
    var body: some View {
        AIBackendStatusMenu(compact: true, showModelPicker: false)
    }
}
