//
//  AISummaryService.swift
//  JiraSummary
//
//  Local Ollama LLM client for natural language summaries
//  Keeps all ticket data private — never leaves the machine
//  Created by Jordan Koch on 2026-02-17.
//

import Foundation
import os.log

actor AISummaryService {
    static let shared = AISummaryService()

    private let logger = Logger(subsystem: "com.jordankoch.JiraSummary", category: "AI")
    private var ollamaEndpoint: URL
    private var modelName: String
    private var isAvailable: Bool?

    private init() {
        self.ollamaEndpoint = URL(string: "http://localhost:11434")!
        self.modelName = "llama3"
    }

    // MARK: - Configuration

    func configure(endpoint: URL, model: String) {
        self.ollamaEndpoint = endpoint
        self.modelName = model
        self.isAvailable = nil
    }

    // MARK: - Availability Check

    func checkAvailability() async -> Bool {
        do {
            let url = ollamaEndpoint.appendingPathComponent("/api/tags")
            let (_, response) = try await URLSession.shared.data(from: url)
            let available = (response as? HTTPURLResponse)?.statusCode == 200
            self.isAvailable = available
            return available
        } catch {
            logger.info("Ollama not available: \(error.localizedDescription)")
            self.isAvailable = false
            return false
        }
    }

    // MARK: - Generate Summary

    func generateSummary(for personSummary: PersonSummary) async -> String? {
        // Check availability first
        if isAvailable == nil { _ = await checkAvailability() }
        guard isAvailable == true else { return nil }

        let prompt = buildPrompt(from: personSummary)

        do {
            let url = ollamaEndpoint.appendingPathComponent("/api/generate")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60

            let body: [String: Any] = [
                "model": modelName,
                "prompt": prompt,
                "stream": false,
                "options": [
                    "temperature": 0.3,
                    "num_predict": 300
                ]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                logger.error("Ollama returned non-200 status")
                return nil
            }

            struct OllamaResponse: Decodable {
                let response: String
            }

            let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
            let trimmed = ollamaResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("AI summary generated for \(personSummary.personName)")
            return trimmed

        } catch {
            logger.error("AI summary failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Prompt Builder

    private func buildPrompt(from summary: PersonSummary) -> String {
        var lines: [String] = []
        lines.append("You are a concise engineering manager writing a brief activity summary.")
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
