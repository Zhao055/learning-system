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

        // Priority 2: Late night — 体贴：关心作息
        if hour >= 22 {
            messages.append(ProactiveMessage(
                content: "很晚了，\(profile.childName)。今天学够多了，早点休息吧。"
            ))
            return messages
        }

        // Priority 2.5: Emotion check — 体贴：近期情绪下降时主动关心
        let emotionProfile = EmotionEngine.shared.profile
        if emotionProfile.currentMoodTrend == .declining {
            messages.append(ProactiveMessage(
                content: "最近学习时间少了些，没事，发生什么了吗？不想聊学习也可以随便聊聊。"
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

        // Priority 5: Weak area insight — 智能主动出现
        // 设计图 14:00 场景："积分换元连续错了3次，我准备了5道专项"
        let weakAreas = analyzeWeakAreas()
        if let topWeak = weakAreas.first, topWeak.attempts >= 3 {
            let wrongCount = topWeak.attempts - Int(Double(topWeak.attempts) * topWeak.accuracy)
            messages.append(ProactiveMessage(
                content: "\(topWeak.kpTitle)你已经练了\(topWeak.attempts)次，有\(wrongCount)次不太顺。我帮你准备了专项练习，换个角度突破它？",
                messageType: .suggestion,
                suggestionData: SuggestionData(text: "开始\(topWeak.kpTitle)专项", action: .startChallenge)
            ))
            return messages
        } else if let insight = generateLearningInsight(profile: profile) {
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
        let recentMoments = ConversationMemoryService.shared.getRecentMoments(limit: 10)

        // 热爱品格：记得孩子的梦想，在合适时候引用
        if let dream = recentMoments.first(where: { $0.category == .dream }) {
            let daysAgo = Calendar.current.dateComponents([.day], from: dream.timestamp, to: Date()).day ?? 0
            if daysAgo >= 3 && daysAgo <= 14 {
                return "\(profile.childName)，你上次提到的梦想，我一直记得。今天我们朝那个方向再进一步？"
            }
        }

        // 体贴品格：如果昨天有挫折，今天主动关心
        if let lastFrustration = recentMoments.first(where: { $0.category == .frustration }) {
            let daysAgo = Calendar.current.dateComponents([.day], from: lastFrustration.timestamp, to: Date()).day ?? 0
            if daysAgo <= 1 {
                return "\(profile.childName)，昨天那道题确实不简单。今天换个角度试试？还是想先聊聊别的？"
            }
        }

        // 数据驱动：基于薄弱点给出具体建议（设计图 07:30 场景）
        let weakAreas = analyzeWeakAreas()
        if let weak = weakAreas.first, profile.stage != .seed {
            return "\(timeGreeting)，\(profile.childName)！\(weak.kpTitle)上次有点卡，今天我们把它搞定？你已经很接近了。"
        }

        // 基于关系阶段
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
