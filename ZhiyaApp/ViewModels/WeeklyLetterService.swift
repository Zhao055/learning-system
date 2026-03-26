import Foundation

/// Generates weekly letters (template-based, or AI-enhanced when available).
@MainActor
final class WeeklyLetterService {
    static let shared = WeeklyLetterService()
    private init() {}

    func checkAndGenerateWeeklyLetter(profile: CompanionProfile, chatCoordinator: ChatCoordinator) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let hour = calendar.component(.hour, from: Date())

        // Sunday evening (weekday 1 = Sunday, after 18:00)
        guard weekday == 1 && hour >= 18 else { return }

        // Don't send if already sent this week
        if let lastLetter = MemoryService.shared.latestLetter() {
            let daysSince = calendar.dateComponents([.day], from: lastLetter.generatedDate, to: Date()).day ?? 0
            if daysSince < 7 { return }
        }

        let weekRecords = ProgressService.shared.records.filter {
            Date().timeIntervalSince1970 - $0.timestamp < 7 * 24 * 3600
        }
        guard !weekRecords.isEmpty else { return }

        // Gather topics
        var topicSet = Set<String>()
        for record in weekRecords {
            if let found = QuestionRepository.shared.findQuestion(questionId: record.questionId, paperId: record.paperId) {
                topicSet.insert(found.kp.titleCn)
            }
        }
        let topics = Array(topicSet.prefix(5))

        let weekCorrect = weekRecords.filter(\.correct).count
        let weekTotal = weekRecords.count
        let weekAccuracy = weekTotal > 0 ? Int(Double(weekCorrect) / Double(weekTotal) * 100) : 0

        let letterContent = generateTemplateWeeklyLetter(
            profile: profile, topics: topics, weekTotal: weekTotal, weekAccuracy: weekAccuracy
        )

        // Save letter
        let now = Date()
        let letter = WeeklyLetter(
            weekStart: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
            weekEnd: now,
            topicsStudied: topics,
            observation: "这周做了\(weekTotal)道题",
            suggestion: weekAccuracy >= 80 ? "继续保持节奏" : "回顾一下薄弱点",
            closing: "下周见",
            generatedDate: now
        )
        MemoryService.shared.addWeeklyLetter(letter)
        chatCoordinator.appendAssistantMessage(letterContent, type: .weeklyLetter)
    }

    private func generateTemplateWeeklyLetter(
        profile: CompanionProfile, topics: [String], weekTotal: Int, weekAccuracy: Int
    ) -> String {
        var lines: [String] = []
        lines.append("亲爱的\(profile.childName)，")
        lines.append("")
        lines.append("这周你学了\(topics.joined(separator: "、"))，一共做了\(weekTotal)道题，正确率\(weekAccuracy)%。")
        lines.append("")
        if weekAccuracy >= 80 {
            lines.append("状态很好，这个节奏继续保持。")
        } else if weekAccuracy >= 50 {
            lines.append("有些知识点还需要巩固，但方向是对的。下周我们一起加油。")
        } else {
            lines.append("这周有点辛苦，但每一次错误都在帮你建立更牢固的理解。")
        }
        if !profile.goals.isEmpty {
            lines.append("距离\(profile.goals)，又近了一步。")
        }
        lines.append("")
        lines.append("下周见。")
        lines.append("")
        lines.append("知芽")
        return lines.joined(separator: "\n")
    }
}
