import Foundation

/// Generates weekly letters — 成长见证：每周日的温暖信件
/// 设计原则：不是冷冰冰的数据报告，而是有品格的成长见证
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

        // Gather memories from this week
        let weekMoments = ConversationMemoryService.shared.getRecentMoments(limit: 20).filter {
            Calendar.current.dateComponents([.day], from: $0.timestamp, to: Date()).day ?? 999 <= 7
        }

        // Analyze weak areas for improvement tracking
        let weakAreas = ProactiveEngine.shared.analyzeWeakAreas()

        let letterContent = generateMemoryDrivenLetter(
            profile: profile,
            topics: topics,
            weekTotal: weekTotal,
            weekAccuracy: weekAccuracy,
            moments: weekMoments,
            weakAreas: weakAreas
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

    /// 记忆驱动的周信 — 不是数据报告，是成长见证
    private func generateMemoryDrivenLetter(
        profile: CompanionProfile,
        topics: [String],
        weekTotal: Int,
        weekAccuracy: Int,
        moments: [ConversationMemoryService.SignificantMoment],
        weakAreas: [ProactiveEngine.WeakArea]
    ) -> String {
        var lines: [String] = []
        lines.append("亲爱的\(profile.childName)，")
        lines.append("")

        // 开篇：如果这周没做题，也写一封温暖的信
        if weekTotal == 0 {
            lines.append("这周你没怎么做题，没关系。休息也是成长的一部分。")
            lines.append("")
            if let dream = moments.first(where: { $0.category == .dream }) {
                lines.append("你说过的梦想，我一直记得。什么时候想继续，我都在。")
            } else {
                lines.append("不管什么时候回来，我都在这里等你。")
            }
            lines.append("")
            lines.append("知芽")
            return lines.joined(separator: "\n")
        }

        // 热爱品格：具体的进步，不是空洞的数字
        if topics.count == 1 {
            lines.append("这周你专注在\(topics[0])上，做了\(weekTotal)道题。")
        } else if !topics.isEmpty {
            lines.append("这周你学了\(topics.prefix(3).joined(separator: "、"))，一共做了\(weekTotal)道题。")
        }
        lines.append("")

        // 包容品格：只和自己比，看到真实的进步
        let breakthroughs = moments.filter { $0.category == .breakthrough }
        if !breakthroughs.isEmpty {
            lines.append("这周有个让我印象深刻的时刻——")
            lines.append("你说「\(breakthroughs.first!.content)」。")
            lines.append("那种自己想明白的感觉，是最珍贵的。")
            lines.append("")
        }

        // 体贴品格：如果有挫折，先关心
        let frustrations = moments.filter { $0.category == .frustration }
        if !frustrations.isEmpty {
            lines.append("这周也有一些不太顺的时候。")
            lines.append("但你没有放弃，这本身就很了不起。")
            lines.append("")
        }

        // 正直品格：诚实地指出薄弱点，但带着温暖
        if weekAccuracy >= 80 {
            lines.append("正确率\(weekAccuracy)%，状态很稳。这个节奏继续保持。")
        } else if weekAccuracy >= 50 {
            if let weakArea = weakAreas.first {
                lines.append("\(weakArea.kpTitle)还需要再练一练，不着急，下周我们一起突破它。")
            } else {
                lines.append("有些地方还需要巩固，但方向是对的。")
            }
        } else {
            lines.append("这周遇到不少挑战。不过每一次出错，都是在帮你建立更牢固的理解。")
        }
        lines.append("")

        // 热爱品格：引用梦想
        if let dream = moments.first(where: { $0.category == .dream }) {
            lines.append("你说过\(dream.content)。")
            lines.append("每做一道题，都在离那个目标更近一步。")
            lines.append("")
        } else if !profile.goals.isEmpty {
            lines.append("距离\(profile.goals)，又近了一步。")
            lines.append("")
        }

        // 结尾
        lines.append("下周见。我会继续陪着你。")
        lines.append("")
        lines.append("知芽")
        return lines.joined(separator: "\n")
    }
}
