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

        // Priority 5: Weak area insight
        if let insight = generateLearningInsight(profile: profile) {
            messages.append(insight)
            return messages
        }

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

        // Try to reference a memory for personalization
        let recentMoments = ConversationMemoryService.shared.getRecentMoments(limit: 3)
        if let lastBreakthrough = recentMoments.first(where: { $0.category == .breakthrough }) {
            return "\(profile.childName)，上次你在学习中有个突破时刻，今天继续挑战？"
        }

        switch profile.stage {
        case .seed:
            return "\(timeGreeting)，\(profile.childName)！"
        case .familiar:
            if stats.totalAnswered > 0 {
                return "\(profile.childName)，今天状态怎么样？"
            }
            return "又见面了，\(profile.childName)！"
        case .understanding, .companion:
            // Reference weak areas if available
            if let weakArea = analyzeWeakAreas().first {
                return "\(profile.childName)，上次\(weakArea.kpTitle)有点卡住了。今天要不从这里开始？"
            }
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

    // MARK: - Pattern Analysis (Local Decision Engine)

    struct WeakArea {
        let kpId: String
        let kpTitle: String
        let accuracy: Double
        let attempts: Int
    }

    /// Analyze wrong answer patterns to find weak knowledge areas
    func analyzeWeakAreas() -> [WeakArea] {
        let records = ProgressService.shared.records

        // Group by KP
        var kpStats: [String: (correct: Int, total: Int, paperId: String, chapterId: String)] = [:]
        for record in records {
            var stat = kpStats[record.kpId] ?? (correct: 0, total: 0, paperId: record.paperId, chapterId: record.chapterId)
            stat.total += 1
            if record.correct { stat.correct += 1 }
            kpStats[record.kpId] = stat
        }

        // Find KPs with accuracy < 60% and at least 2 attempts
        var weakAreas: [WeakArea] = []
        for (kpId, stat) in kpStats where stat.total >= 2 {
            let accuracy = Double(stat.correct) / Double(stat.total)
            if accuracy < 0.6 {
                let title = QuestionRepository.shared.getKnowledgePoint(
                    stat.paperId, chapterId: stat.chapterId, kpId: kpId
                )?.titleCn ?? kpId
                weakAreas.append(WeakArea(kpId: kpId, kpTitle: title, accuracy: accuracy, attempts: stat.total))
            }
        }

        // Sort by worst accuracy first
        return weakAreas.sorted { $0.accuracy < $1.accuracy }
    }

    /// Generate a personalized learning suggestion based on pattern analysis
    func generateLearningInsight(profile: CompanionProfile) -> ProactiveMessage? {
        let weakAreas = analyzeWeakAreas()

        guard !weakAreas.isEmpty else { return nil }

        if weakAreas.count == 1 {
            let area = weakAreas[0]
            return ProactiveMessage(
                content: "我注意到\(area.kpTitle)的正确率是\(Int(area.accuracy * 100))%。要不我们重点练一下？",
                messageType: .suggestion,
                suggestionData: SuggestionData(text: "练习\(area.kpTitle)", action: .startChallenge)
            )
        } else {
            let topTwo = weakAreas.prefix(2).map(\.kpTitle).joined(separator: "和")
            return ProactiveMessage(
                content: "你在\(topTwo)这两个知识点上还可以加强。要不从薄弱点开始？",
                messageType: .suggestion,
                suggestionData: SuggestionData(text: "开始练习", action: .startChallenge)
            )
        }
    }
}
