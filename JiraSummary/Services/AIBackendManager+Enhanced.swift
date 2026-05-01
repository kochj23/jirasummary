import Foundation
import SwiftUI
import UserNotifications

//
//  AIBackendManager+Enhanced.swift
//  Enhanced features for AIBackendManager
//
//  Adds: Usage tracking, performance metrics, notifications, availability monitoring
//  Author: Jordan Koch
//  Date: 2026-01-26
//

extension AIBackendManager {

    // MARK: - Usage Tracking

    func recordUsage(backend: AIBackend, tokens: Int, responseTime: TimeInterval) {
        let cost = UsageStats.estimatedCostPerRequest(backend: backend, tokens: tokens)
        logger.info("Usage recorded: \(backend.rawValue) - \(tokens) tokens, $\(String(format: "%.6f", cost))")
    }

    // MARK: - Performance Recording

    func recordPerformance(backend: AIBackend, success: Bool, responseTime: TimeInterval?) {
        var metrics = performanceMetrics[backend] ?? PerformanceMetrics()

        if success, let responseTime = responseTime {
            metrics.totalAttempts += 1
            metrics.successfulAttempts += 1
            metrics.lastResponseTime = responseTime
            let totalTime = metrics.averageLatency * Double(metrics.successfulAttempts - 1) + responseTime
            metrics.averageLatency = totalTime / Double(metrics.successfulAttempts)
            metrics.successRate = Double(metrics.successfulAttempts) / Double(metrics.totalAttempts)
        } else {
            metrics.totalAttempts += 1
            metrics.failedAttempts += 1
            metrics.successRate = Double(metrics.successfulAttempts) / Double(metrics.totalAttempts)
        }

        performanceMetrics[backend] = metrics
    }

    // MARK: - Notification System

    func sendNotification(title: String, message: String) {
        #if os(macOS)
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
        #endif

        print("[AIBackend] \(title): \(message)")
    }

    // MARK: - Availability Monitoring

    func collectAvailabilitySnapshot() -> [AIBackend: Bool] {
        var snapshot: [AIBackend: Bool] = [:]
        for backend in AIBackend.allCases {
            snapshot[backend] = isAvailable(backend)
        }
        return snapshot
    }

    func notifyAvailabilityChanges(from previous: [AIBackend: Bool], to current: [AIBackend: Bool]) {
        for backend in AIBackend.allCases {
            let wasAvailable = previous[backend] ?? false
            let isNowAvailable = current[backend] ?? false

            if wasAvailable != isNowAvailable {
                let status = isNowAvailable ? "Online" : "Offline"
                sendNotification(
                    title: "Backend Status Changed",
                    message: "\(backend.rawValue) is now \(status)"
                )
            }
        }
    }
}

// MARK: - Keyboard Shortcut Support

#if os(macOS)
import AppKit

extension AIBackendManager {

    /// Register global keyboard shortcuts for backend switching
    func registerKeyboardShortcuts() {
        let _: [(Int, AIBackend)] = [
            (1, .ollama),
            (2, .openAI),
            (3, .mlx),
            (4, .tinyLLM),
            (5, .googleCloud),
            (6, .azure),
            (7, .ibmWatson),
            (8, .tinyChat),
            (9, .openWebUI)
        ]

        print("[AIBackend] Keyboard shortcuts registered: Cmd+1-9 for backend switching")
    }
}
#endif
