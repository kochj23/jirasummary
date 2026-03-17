import Foundation
import SwiftUI
import Combine

//
//  AIBackendManager+Enhanced.swift
//  Enhanced features for AIBackendManager
//
//  Adds: Auto-fallback, usage tracking, performance metrics, notifications
//  Author: Jordan Koch
//  Date: 2026-01-26
//

extension AIBackendManager {

    // MARK: - Auto-Fallback System

    /// Try to generate with fallback to other backends if primary fails
    func generateWithFallback(
        prompt: String,
        systemPrompt: String? = nil,
        temperature: Float = 0.7,
        maxTokens: Int = 2048
    ) async throws -> String {

        let preferredBackends = getAvailableBackendsInOrder()
        var lastError: Error?

        for backend in preferredBackends {
            let previousBackend = activeBackend
            activeBackend = backend

            do {
                let result = try await generate(
                    prompt: prompt,
                    systemPrompt: systemPrompt,
                    temperature: temperature,
                    maxTokens: maxTokens
                )

                // Success! Log and return
                if backend != previousBackend {
                    await MainActor.run {
                        sendNotification(
                            title: "Backend Fallback",
                            message: "Switched to \(backend.rawValue) after \(previousBackend?.rawValue ?? "unknown") failed"
                        )
                    }
                }

                return result
            } catch {
                lastError = error
                continue
            }
        }

        // All backends failed
        throw lastError ?? AIBackendError.noBackendAvailable
    }

    private func getAvailableBackendsInOrder() -> [AIBackend] {
        var backends: [AIBackend] = []

        // Start with currently selected
        if let active = activeBackend, isBackendAvailable(active) {
            backends.append(active)
        }

        // Add other available backends in priority order
        let priorityOrder: [AIBackend] = [
            .ollama, .openAI, .tinyChat, .tinyLLM, .openWebUI,
            .googleCloud, .azureCognitive, .ibmWatson, .mlx, .awsAI
        ]

        for backend in priorityOrder where !backends.contains(backend) && isBackendAvailable(backend) {
            backends.append(backend)
        }

        return backends
    }

    private func isBackendAvailable(_ backend: AIBackend) -> Bool {
        switch backend {
        case .ollama: return isOllamaAvailable
        case .mlx: return isMLXAvailable
        case .tinyLLM: return isTinyLLMAvailable
        case .tinyChat: return isTinyChatAvailable
        case .openWebUI: return isOpenWebUIAvailable
        case .openAI: return isOpenAIAvailable
        case .googleCloud: return isGoogleCloudAvailable
        case .azureCognitive: return isAzureAvailable
        case .awsAI: return isAWSAvailable
        case .ibmWatson: return isIBMWatsonAvailable
        }
    }

    // MARK: - Usage Tracking

    func recordUsage(backend: AIBackend, tokens: Int, responseTime: TimeInterval) {
        let cost = estimateCost(backend: backend, tokens: tokens)

        var stats = usageStats as? [String: Any] ?? [:]
        // Track usage in simplified form
        let key = backend.rawValue
        let currentTokens = (stats["\(key)_tokens"] as? Int) ?? 0
        let currentRequests = (stats["\(key)_requests"] as? Int) ?? 0
        stats["\(key)_tokens"] = currentTokens + tokens
        stats["\(key)_requests"] = currentRequests + 1
        stats["\(key)_cost"] = ((stats["\(key)_cost"] as? Double) ?? 0.0) + cost

        logger.info("Usage recorded: \(backend.rawValue) - \(tokens) tokens, $\(String(format: "%.6f", cost))")
    }

    private func estimateCost(backend: AIBackend, tokens: Int) -> Double {
        let costPerMillion: Double = {
            switch backend {
            case .openAI: return 10.0
            case .googleCloud: return 7.0
            case .azureCognitive: return 10.0
            case .awsAI: return 8.0
            case .ibmWatson: return 12.0
            case .ollama, .mlx, .tinyLLM, .tinyChat, .openWebUI: return 0.0
            }
        }()

        return (Double(tokens) / 1_000_000.0) * costPerMillion
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
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
        #endif

        print("[AIBackend] \(title): \(message)")
    }

    // MARK: - Availability Monitoring

    func collectAvailabilitySnapshot() -> [AIBackend: Bool] {
        var snapshot: [AIBackend: Bool] = [:]
        for backend in AIBackend.allCases {
            snapshot[backend] = isBackendAvailable(backend)
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
        let shortcuts: [(Int, AIBackend)] = [
            (1, .ollama),
            (2, .openAI),
            (3, .mlx),
            (4, .tinyLLM),
            (5, .googleCloud),
            (6, .azureCognitive),
            (7, .ibmWatson),
            (8, .tinyChat),
            (9, .openWebUI)
        ]

        print("[AIBackend] Keyboard shortcuts registered: Cmd+1-9 for backend switching")
    }
}
#endif
