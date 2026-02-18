//
//  AISummaryService.swift
//  JiraSummary
//
//  AI-powered natural language summaries for person activity
//  Delegates to AIBackendManager for multi-backend generation
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation
import os.log

actor AISummaryService {
    static let shared = AISummaryService()

    private let logger = Logger(subsystem: "com.jordankoch.JiraSummary", category: "AISummary")

    private init() {}

    // MARK: - Generate Summary

    func generateSummary(for personSummary: PersonSummary) async -> String? {
        let manager = await AIBackendManager.shared

        guard await manager.isEnabled else {
            logger.info("AI summaries disabled")
            return nil
        }

        guard await manager.anyBackendAvailable else {
            logger.warning("No AI backends available")
            return nil
        }

        let prompt = buildPrompt(from: personSummary)
        let systemPrompt = "You are a concise engineering manager writing brief activity summaries. Be specific and factual. Write in 2-3 sentences maximum."

        do {
            let result = try await manager.generateWithFallback(
                prompt: prompt,
                systemPrompt: systemPrompt
            )
            logger.info("AI summary generated for \(personSummary.personName)")
            return result
        } catch {
            logger.error("AI summary failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Batch Summaries

    func generateSummaries(for summaries: [PersonSummary]) async -> [String: String] {
        var results: [String: String] = [:]
        for summary in summaries {
            if let text = await generateSummary(for: summary) {
                results[summary.id.uuidString] = text
            }
        }
        return results
    }

    // MARK: - Prompt Builder

    private func buildPrompt(from summary: PersonSummary) -> String {
        var lines: [String] = []
        lines.append("Summarize this person's work activity in 2-3 sentences. Be specific about what they accomplished.")
        lines.append("")
        lines.append("Person: \(summary.personName)")
        lines.append("System: \(summary.systemName)")
        lines.append("Period: \(summary.period.rawValue)")
        lines.append("Total tickets touched: \(summary.totalTickets)")
        lines.append("Completed: \(summary.ticketsCompleted)")
        lines.append("In progress: \(summary.ticketsInProgress)")
        lines.append("Blocked: \(summary.ticketsBlocked)")
        lines.append("Created: \(summary.ticketsCreated)")

        if summary.committedPoints > 0 {
            lines.append("Sprint: \(summary.sprintName ?? "Current")")
            lines.append("Points committed: \(Int(summary.committedPoints)), completed: \(Int(summary.completedPoints))")
        }

        if !summary.recentTickets.isEmpty {
            lines.append("")
            lines.append("Recent tickets:")
            for ticket in summary.recentTickets.prefix(5) {
                lines.append("- \(ticket.ticketKey): \(ticket.title) [\(ticket.currentStatus)]")
            }
        }

        lines.append("")
        lines.append("Write a brief, factual summary (2-3 sentences):")

        return lines.joined(separator: "\n")
    }
}
