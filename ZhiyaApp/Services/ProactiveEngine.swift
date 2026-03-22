import Foundation

final class ProactiveEngine {
    static let shared = ProactiveEngine()

    private init() {}

    struct ProactiveMessage {
        let content: String
        let messageType: MessageType
        let suggestionData: SuggestionData?

        init(content: String, messageType: MessageType = .text, suggestionData: SuggestionData? = nil) {
            self.content = content
            self.messageType = messageType
            self.suggestionData = suggestionData
        }
    }

    /// Generate proactive messages based on current context
    func generateMessages(profile: CompanionProfile, lastMessageTimestamp: TimeInterval?) -> [ProactiveMessage] {
        var messages: [ProactiveMessage] = []
        let hour = Calendar.current.component(.hour, from: Date())
        let now = Date().timeIntervalSince1970

        // Calculate days since last interaction
        let daysSinceLastMessage: Int = {
            guard let last = lastMessageTimestamp else { return 999 }
            let lastDate = Date(timeIntervalSince1970: last)
            return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        }()

        // Check consecutive days (simplified)
        let stats = ProgressService.shared.getTotalStats()

        // Priority 1: Long absence
        if daysSinceLastMessage >= 3 {
            messages.append(ProactiveMessage(
                content: "好几天没见了，\(profile.childName)。没事，什么时候想回来，我都在。"
            ))
            return messages
        }

        // Priority 2: Late night
        if hour >= 22 {
            messages.append(ProactiveMessage(
                content: "很晚了，\(profile.childName)。今天学够多了，早点休息吧。"
            ))
            return messages
        }

        // Priority 3: Exam countdown
        if let examDate = profile.examDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: examDate).day ?? 0
            if days > 0 && days <= 7 {
                messages.append(ProactiveMessage(
                    content: "考试还有\(days)天。我帮你理了一个复习重点，要看吗？",
                    messageType: .suggestion,
                    suggestionData: SuggestionData(text: "查看复习计划", action: .startReview)
                ))
                return messages
            }
        }

        // Priority 4: KP due for review
        let dueCount = countDueKnowledgePoints()
        if dueCount > 0 {
            messages.append(ProactiveMessage(
                content: "有\(dueCount)个知识点好几天没碰了，来一道保持手感？",
                messageType: .suggestion,
                suggestionData: SuggestionData(text: "来一道", action: .startChallenge)
            ))
            return messages
        }

        // Priority 5: Streak celebration
        // (Simplified - would need proper streak tracking)

        // Priority 6: Morning/evening rhythm
        if hour >= 6 && hour < 10 {
            messages.append(ProactiveMessage(
                content: "早上好，\(profile.childName)！新的一天，热身几道？",
                messageType: .suggestion,
                suggestionData: SuggestionData(text: "热身一下", action: .startChallenge)
            ))
        } else if hour >= 18 && hour < 22 {
            if stats.totalAnswered > 0 {
                messages.append(ProactiveMessage(
                    content: "\(profile.childName)，回顾下今天学的？",
                    messageType: .suggestion,
                    suggestionData: SuggestionData(text: "开始回顾", action: .startReview)
                ))
            } else {
                messages.append(ProactiveMessage(
                    content: "晚上好，\(profile.childName)！今天想聊点什么？"
                ))
            }
        } else {
            // Default greeting
            let greeting = generateContextualGreeting(profile: profile, stats: stats)
            messages.append(ProactiveMessage(content: greeting))
        }

        return messages
    }

    private func generateContextualGreeting(profile: CompanionProfile, stats: TotalStats) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting = hour < 12 ? "上午好" : hour < 18 ? "下午好" : "晚上好"

        switch profile.stage {
        case .seed:
            return "\(timeGreeting)，\(profile.childName)！"
        case .familiar:
            if stats.totalAnswered > 0 {
                return "\(profile.childName)，今天状态怎么样？"
            }
            return "又见面了，\(profile.childName)！"
        case .understanding, .companion:
            return "\(profile.childName)，今天想做什么？"
        }
    }

    private func countDueKnowledgePoints() -> Int {
        let records = ProgressService.shared.records
        let now = Date().timeIntervalSince1970
        let threeDays: TimeInterval = 3 * 24 * 3600

        var kpLastTime: [String: TimeInterval] = [:]
        for record in records {
            if let existing = kpLastTime[record.kpId] {
                if record.timestamp > existing {
                    kpLastTime[record.kpId] = record.timestamp
                }
            } else {
                kpLastTime[record.kpId] = record.timestamp
            }
        }

        return kpLastTime.filter { now - $0.value > threeDays }.count
    }
}
