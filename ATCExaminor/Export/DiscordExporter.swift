import Foundation

enum ExportError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:    return "The webhook URL is invalid."
        case .httpError(let code): return "Discord returned HTTP \(code). Check the webhook URL."
        case .noData:        return "No response received from Discord."
        }
    }
}

struct DiscordExporter {

    // MARK: - Default templates

    static let defaultMainTemplate = """
# {{candidateName}}
{{sectionBlock:S1}}{{sectionBlock:S2}}{{sectionBlock:S3}}{{sectionBlock:C1}}# Extra Points:
{{extraPointsBlock}}**__Raw Score: {{rawScore}}__**
*Extra Points: {{extraDelta}}*
**Final Score: {{finalScore}}**
*Passing Score: {{finalThreshold}}*
**__Result: {{finalResult}}__**
"""

    static let defaultSectionTemplate = """
# {{sectionTitle}}
{{groupBlocks}}**Total Score: {{totalScore}}**
*Passing Score: {{passingScore}}*
**__Result: {{sectionResult}}__**

"""

    static let defaultGroupTemplate = """
**__{{groupLabel}}__**
{{criteriaList}}
"""

    // MARK: - Report generation

    static func generateReport(session: Session) -> String {
        let mainTemplate = UserDefaults.standard.string(forKey: "discordReportTemplate") ?? defaultMainTemplate
        let sectionTemplate = UserDefaults.standard.string(forKey: "sectionBlockTemplate") ?? defaultSectionTemplate
        let groupTemplate = UserDefaults.standard.string(forKey: "groupBlockTemplate") ?? defaultGroupTemplate

        let fullMark = UserDefaults.standard.string(forKey: "markSymbolFull") ?? "✅"
        let halfMark = UserDefaults.standard.string(forKey: "markSymbolHalf") ?? "🟡"
        let noneMark = UserDefaults.standard.string(forKey: "markSymbolNone") ?? "❌"

        let finalThreshold = UserDefaults.standard.double(forKey: "finalPassingThreshold").nonZeroOr(84.0)

        var report = mainTemplate
        report = report.replacingOccurrences(of: "{{candidateName}}", with: session.candidateName)


        for level in RatingLevel.allCases {
            let token = "{{sectionBlock:\(level.rawValue)}}"
            guard session.targetRating.requiredLevels.contains(level) else {
                report = report.replacingOccurrences(of: token, with: "")
                continue
            }

            let criteria = session.criterionScores
                .filter { $0.ratingLevel == level }
                .sorted { $0.orderIndex < $1.orderIndex }

            let sectionScore = ScoringEngine.sectionScore(criteria: criteria)
            let threshold = level.defaultPassingThreshold
            let total = criteria.count
            let achieved = criteria.reduce(0.0) { $0 + ($1.mark?.rawValue ?? 0) }

            // Group blocks
            var groupBlocks = ""
            let groups = groupedCriteria(criteria)
            for (label, groupCriteria) in groups {
                var criteriaList = ""
                for c in groupCriteria {
                    let symbol: String
                    switch c.mark {
                    case .some(.full):  symbol = fullMark
                    case .some(.half):  symbol = halfMark
                    case .some(.none):  symbol = noneMark
                    case .none:         symbol = "⬜"
                    }
                    let noteStr = c.note.isEmpty ? "" : " (\(c.note))"
                    criteriaList += "- \(c.criterionText) \(symbol)\(noteStr)\n"
                }

                if label.isEmpty {
                    groupBlocks += criteriaList
                } else {
                    var block = groupTemplate
                    block = block.replacingOccurrences(of: "{{groupLabel}}", with: label)
                    block = block.replacingOccurrences(of: "{{criteriaList}}", with: criteriaList)
                    groupBlocks += block
                }
            }

            let scoreStr = sectionScore != nil
                ? String(format: "%.1f/%d", achieved, total)
                : "–/\(total)"
            let percentStr = sectionScore != nil
                ? String(format: "%.0f%%", sectionScore! * 100)
                : "–"
            let passed = sectionScore != nil && sectionScore! >= threshold

            var sectionBlock = sectionTemplate
            sectionBlock = sectionBlock.replacingOccurrences(of: "{{sectionTitle}}", with: level.displayName)
            sectionBlock = sectionBlock.replacingOccurrences(of: "{{groupBlocks}}", with: groupBlocks)
            sectionBlock = sectionBlock.replacingOccurrences(of: "{{totalScore}}", with: "\(scoreStr) (\(percentStr))")
            sectionBlock = sectionBlock.replacingOccurrences(of: "{{passingScore}}", with: String(format: "%.0f%%", threshold * 100))
            sectionBlock = sectionBlock.replacingOccurrences(of: "{{sectionResult}}", with: sectionScore == nil ? "–" : (passed ? "PASS" : "FAIL"))

            report = report.replacingOccurrences(of: token, with: sectionBlock)
        }

        // Extra points block
        let extraEntries = session.extraEntries.sorted { $0.createdAt < $1.createdAt }
        let extraBlock: String
        if extraEntries.isEmpty {
            extraBlock = ""
        } else {
            extraBlock = extraEntries.map { entry in
                let sign = entry.value >= 0 ? "+" : ""
                return "- \(entry.note): \(sign)\(String(format: "%.1f", entry.value))"
            }.joined(separator: "\n") + "\n"
        }
        report = report.replacingOccurrences(of: "{{extraPointsBlock}}", with: extraBlock)

        // Score tokens
        let rawScore = ScoringEngine.sectionAverage(session: session)
        let finalScore = ScoringEngine.finalScore(session: session)
        let extraDelta = ScoringEngine.extraDelta(session: session)
        let passed = ScoringEngine.overallPassed(session: session, finalThreshold: finalThreshold)

        report = report.replacingOccurrences(of: "{{rawScore}}", with: rawScore != nil ? String(format: "%.1f%%", rawScore!) : "–")
        report = report.replacingOccurrences(of: "{{extraDelta}}", with: extraDelta >= 0
            ? String(format: "+%.1f%%", extraDelta)
            : String(format: "%.1f%%", extraDelta))
        report = report.replacingOccurrences(of: "{{finalScore}}", with: finalScore != nil ? String(format: "%.1f%%", finalScore!) : "–")
        report = report.replacingOccurrences(of: "{{finalThreshold}}", with: String(format: "%.0f%%", finalThreshold))
        report = report.replacingOccurrences(of: "{{finalResult}}", with: passed == nil ? "–" : (passed! ? "PASS" : "FAIL"))

        return report
    }

    // MARK: - Webhook POST

    static func send(report: String, to webhookURL: String) async throws {
        guard let url = URL(string: webhookURL) else { throw ExportError.invalidURL }
        for chunk in splitIntoChunks(report) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["content": chunk])
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ExportError.noData }
            guard (200...299).contains(http.statusCode) else { throw ExportError.httpError(http.statusCode) }
        }
    }

    // MARK: - Chunk splitter

    static func splitIntoChunks(_ text: String, maxLength: Int = 2000) -> [String] {
        guard text.count > maxLength else { return [text] }

        var chunks: [String] = []
        var remaining = text[text.startIndex...]

        while !remaining.isEmpty {
            if remaining.count <= maxLength {
                chunks.append(String(remaining))
                break
            }

            let windowEnd = remaining.index(remaining.startIndex, offsetBy: maxLength)
            let window = remaining[remaining.startIndex ..< windowEnd]


            if let range = window.range(of: "\n# ", options: .backwards) {
                chunks.append(String(remaining[remaining.startIndex ..< range.lowerBound]))
                remaining = remaining[range.lowerBound...]
                continue
            }


            if let range = window.range(of: "\n\n", options: .backwards) {
                chunks.append(String(remaining[remaining.startIndex ..< range.upperBound]))
                remaining = remaining[range.upperBound...]
                continue
            }


            if let range = window.range(of: "\n", options: .backwards) {
                chunks.append(String(remaining[remaining.startIndex ..< range.upperBound]))
                remaining = remaining[range.upperBound...]
                continue
            }

            chunks.append(String(window))
            remaining = remaining[windowEnd...]
        }

        return chunks
    }

    // MARK: - Helpers

    private static func groupedCriteria(_ criteria: [CriterionScore]) -> [(String, [CriterionScore])] {
        var seen: [String] = []
        var result: [(String, [CriterionScore])] = []
        for c in criteria {
            if !seen.contains(c.groupLabel) {
                seen.append(c.groupLabel)
                result.append((c.groupLabel, []))
            }
            if let idx = result.firstIndex(where: { $0.0 == c.groupLabel }) {
                result[idx].1.append(c)
            }
        }
        return result
    }
}
