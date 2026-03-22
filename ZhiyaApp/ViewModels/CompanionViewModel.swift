import SwiftUI
import Combine

@MainActor
final class CompanionViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var showGarden: Bool = false
    @Published var showSettings: Bool = false
    @Published var showCamera: Bool = false
    @Published var isRecording: Bool = false
    @Published var showCelebration: Bool = false
    @Published var currentMilestone: Milestone?
    @Published var mascotCollapsed: Bool = false

    private let companionEngine: CompanionEngine
    private let messagesKey = "zhiya_companion_messages"
    private var cancellables = Set<AnyCancellable>()
    private var consecutiveWrongCount: Int = 0

    init(companionEngine: CompanionEngine) {
        self.companionEngine = companionEngine
        loadMessages()
    }

    // MARK: - Proactive Messages

    func generateProactiveMessages() {
        // Don't add proactive messages if we already have recent ones
        if let last = messages.last, last.role == .assistant,
           Date().timeIntervalSince1970 - last.timestamp < 60 { return }

        // Check for Synapse proactive messages first
        let synapseMessages = NotificationService.shared.consumePendingMessages()
        for msg in synapseMessages {
            appendAssistantMessage(msg.body, type: msg.messageType)
        }

        // If no Synapse messages, use local proactive engine
        if synapseMessages.isEmpty {
            let lastTimestamp = messages.last?.timestamp
            let proactiveMessages = ProactiveEngine.shared.generateMessages(
                profile: companionEngine.profile,
                lastMessageTimestamp: lastTimestamp
            )

            for msg in proactiveMessages {
                appendAssistantMessage(msg.content, type: msg.messageType, suggestionData: msg.suggestionData)
            }

            // Check if it's Sunday evening — generate weekly letter
            checkWeeklyLetter()
        }

        // Record activity
        companionEngine.recordActivity()
    }

    // MARK: - Send Message

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        // Analyze message for significant moments
        ConversationMemoryService.shared.analyzeAndStore(message: userMessage)

        EmotionEngine.shared.updateForChatState(.thinking)

        // Check for special intents
        let intent = detectIntent(text)

        let assistantId = UUID().uuidString
        let placeholder = ChatMessage(id: assistantId, role: .assistant, content: "", isStreaming: true)
        messages.append(placeholder)

        // Collapse mascot when actively chatting
        if !mascotCollapsed {
            withAnimation(.easeOut(duration: 0.3)) { mascotCollapsed = true }
        }

        Task {
            do {
                if AIService.shared.isSynapseAvailable {
                    // Synapse mode: stream with tool_call event parsing
                    let stream = AIService.shared.streamChatViaSynapse(
                        sessionId: "zhiya-companion",
                        message: text
                    )
                    for try await event in stream {
                        switch event {
                        case .text(let chunk):
                            if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                                messages[idx].content += chunk
                            }
                        case .toolCall(let name, let args):
                            handleSynapseToolCall(name: name, arguments: args)
                        case .toolResult(_, _):
                            break // Tool results are handled internally by the agent
                        }
                    }
                } else {
                    // Direct mode: stream via MiniMax/Claude
                    let systemPrompt = companionSystemPrompt(intent: intent)
                    let contextMessages = Array(messages
                        .filter { $0.role != .system && !$0.isStreaming }
                        .suffix(20))
                    let stream = AIService.shared.streamChat(
                        messages: contextMessages,
                        systemPrompt: systemPrompt
                    )
                    for try await chunk in stream {
                        if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                            messages[idx].content += chunk
                        }
                    }
                }
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                }
                EmotionEngine.shared.updateForChatState(.idle)

                // Post-response actions based on intent
                await handlePostResponse(intent: intent)
            } catch {
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].content = "抱歉，出了点问题：\(error.localizedDescription)"
                    messages[idx].isStreaming = false
                }
            }
            isLoading = false
            saveMessages()
        }
    }

    // MARK: - Send Image

    func sendImage(_ imageData: Data) {
        let userMessage = ChatMessage(
            role: .user, content: "📷 [拍了一张照片]",
            messageType: .imageAnalysis, imageData: imageData
        )
        messages.append(userMessage)
        isLoading = true

        // Collapse mascot
        if !mascotCollapsed {
            withAnimation(.easeOut(duration: 0.3)) { mascotCollapsed = true }
        }

        let assistantId = UUID().uuidString
        let placeholder = ChatMessage(id: assistantId, role: .assistant, content: "", isStreaming: true)
        messages.append(placeholder)

        Task {
            do {
                let contextMessages = Array(messages
                    .filter { $0.role != .system && !$0.isStreaming }
                    .suffix(10))
                let stream = AIService.shared.streamChat(
                    messages: contextMessages,
                    systemPrompt: AIService.shared.solverSystemPrompt()
                )
                for try await chunk in stream {
                    if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                        messages[idx].content += chunk
                    }
                }
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                }

                // After image analysis, offer a follow-up challenge
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                appendAssistantMessage("要不要试一道相关的题目练练手？", type: .suggestion,
                    suggestionData: SuggestionData(text: "来一道", action: .startChallenge))
            } catch {
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].content = "抱歉，分析图片时出了问题：\(error.localizedDescription)"
                    messages[idx].isStreaming = false
                }
            }
            isLoading = false
            saveMessages()
        }
    }

    // MARK: - Challenge Card

    func handleChallengeAnswer(messageId: String, selectedIndex: Int) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }),
              var challenge = messages[idx].challengeData,
              !challenge.answered else { return }

        challenge.selectedIndex = selectedIndex
        challenge.answered = true
        challenge.isCorrect = selectedIndex == challenge.correctIndex
        messages[idx].challengeData = challenge

        // Record progress
        ProgressService.shared.recordAnswer(
            paperId: challenge.paperId,
            chapterId: challenge.chapterId,
            kpId: challenge.kpId,
            questionId: challenge.questionId,
            correct: challenge.isCorrect ?? false,
            selectedIndex: selectedIndex
        )

        // Track consecutive wrong
        if challenge.isCorrect == true {
            consecutiveWrongCount = 0
        } else {
            consecutiveWrongCount += 1
        }

        // Update emotion
        EmotionEngine.shared.updateFromQuizResult(correct: challenge.isCorrect ?? false, consecutiveWrong: consecutiveWrongCount)
        companionEngine.onConsecutiveWrong(consecutiveWrongCount)

        // Update growth tree
        let kpProgress = ProgressService.shared.getKpProgress(
            paperId: challenge.paperId, chapterId: challenge.chapterId, kpId: challenge.kpId
        )
        let masteryRate = kpProgress.attempted > 0 ? Double(kpProgress.correct) / Double(kpProgress.attempted) : 0
        let oldLeafCount = MemoryService.shared.growthTree.leaves.count
        MemoryService.shared.updateTreeForProgress(
            dimension: .academic, kpId: challenge.kpId, kpTitle: challenge.kpTitle, masteryRate: masteryRate
        )

        // Emit growth snapshot if new leaf
        if MemoryService.shared.growthTree.leaves.count > oldLeafCount {
            appendAssistantMessage("\(challenge.kpTitle) 掌握度提升了！", type: .growthSnapshot)
        }

        // Check milestones
        let stats = ProgressService.shared.getTotalStats()
        let oldMilestoneCount = MemoryService.shared.milestones.count
        MemoryService.shared.checkMilestones(stats: stats, paperId: challenge.paperId, chapterId: challenge.chapterId)
        if MemoryService.shared.milestones.count > oldMilestoneCount {
            currentMilestone = MemoryService.shared.milestones.last
            showCelebration = true
            // Also add celebration message in chat
            if let milestone = currentMilestone {
                appendAssistantMessage("🎉 \(milestone.title) — \(milestone.description)", type: .celebration)
            }
        }

        // Follow-up response — Socratic style for wrong answers
        if challenge.isCorrect == true {
            appendAssistantMessage("答对了！\(challenge.kpTitle) 掌握得不错。", type: .text)
        } else if consecutiveWrongCount >= 3 {
            // After 3 consecutive wrong, show care first
            appendAssistantMessage("连着几道都有点难，没关系。要不先休息一下，或者我们聊聊别的？", type: .text)
        } else {
            let selectedLetter = ["A", "B", "C", "D"][selectedIndex]
            appendAssistantMessage("你选了\(selectedLetter)，你是怎么想的？来聊聊你的思路。", type: .text)
        }

        saveMessages()
    }

    // MARK: - Suggestion Tap

    func handleSuggestionTap(messageId: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }),
              var suggestion = messages[idx].suggestionData,
              !suggestion.tapped else { return }

        suggestion.tapped = true
        messages[idx].suggestionData = suggestion

        switch suggestion.action {
        case .startReview:
            generateStudyPlan()
        case .startChallenge:
            surfaceChallenge()
        case .viewGarden:
            showGarden = true
        case .dismiss:
            break
        }
    }

    // MARK: - Surface Challenge

    func surfaceChallenge() {
        let service = QuestionSurfacingService.shared
        guard let (question, paperId, chapterId, kpId, kpTitle) = service.getNextQuestion(profile: companionEngine.profile) else {
            appendAssistantMessage("暂时没有合适的题目。继续聊天吧！", type: .text)
            return
        }

        let challengeData = ChallengeData(
            from: question, paperId: paperId, chapterId: chapterId, kpId: kpId, kpTitle: kpTitle
        )

        let message = ChatMessage(
            role: .assistant,
            content: "来试试这道题：",
            messageType: .challengeCard,
            challengeData: challengeData
        )
        messages.append(message)
        saveMessages()
    }

    // MARK: - Synapse Tool Call Handling

    /// Handle tool_call events from Synapse Agent — this is how AI autonomously decides to show challenges, etc.
    private func handleSynapseToolCall(name: String, arguments: [String: Any]) {
        switch name {
        case "zhiya_get_random_question", "zhiya_get_questions":
            // Agent decided to show a question — will come as tool_result with question data
            // The actual ChallengeCard will be created when we receive the tool_result
            break

        case "zhiya_record_answer":
            // Agent recorded an answer — already handled server-side, no UI action needed
            break

        case "memory_write":
            // Agent is remembering something — silent, no UI
            break

        case "memory_read":
            // Agent is reading memory — silent
            break

        case "zhiya_get_stats", "zhiya_get_wrong_answers", "zhiya_get_weak_points",
             "zhiya_get_growth_tree", "zhiya_get_kp_due_review":
            // Agent is gathering data — silent
            break

        default:
            break
        }
    }

    /// Insert a ChallengeCard from Synapse tool_result data
    func insertChallengeFromSynapse(questionData: [String: Any]) {
        guard let stem = questionData["stem"] as? String,
              let options = questionData["options"] as? [String],
              let correctIndex = questionData["correctIndex"] as? Int else { return }

        let challengeData = ChallengeData(
            questionId: questionData["questionId"] as? String ?? questionData["id"] as? String ?? UUID().uuidString,
            paperId: questionData["paperId"] as? String ?? "",
            chapterId: questionData["chapterId"] as? String ?? "",
            kpId: questionData["kpId"] as? String ?? "",
            kpTitle: questionData["kpTitle"] as? String ?? "",
            stem: stem,
            options: options,
            correctIndex: correctIndex,
            explanation: questionData["explanation"] as? String ?? "",
            difficulty: questionData["difficulty"] as? Int ?? 1
        )

        let message = ChatMessage(
            role: .assistant,
            content: "",
            messageType: .challengeCard,
            challengeData: challengeData
        )
        messages.append(message)
        saveMessages()
    }

    // MARK: - Intent Detection

    private enum UserIntent {
        case general
        case wantToStudy
        case dontWantToStudy
        case askAboutExam
        case emotionalSupport
        case askForChallenge
    }

    private func detectIntent(_ text: String) -> UserIntent {
        let lower = text.lowercased()
        if lower.contains("不想学") || lower.contains("不想做题") || lower.contains("累了") || lower.contains("烦了") {
            return .dontWantToStudy
        }
        if lower.contains("出题") || lower.contains("做题") || lower.contains("练习") || lower.contains("来一道") {
            return .askForChallenge
        }
        if lower.contains("考试") || lower.contains("exam") {
            return .askAboutExam
        }
        if lower.contains("压力") || lower.contains("焦虑") || lower.contains("难过") || lower.contains("不开心") {
            return .emotionalSupport
        }
        return .general
    }

    private func handlePostResponse(intent: UserIntent) async {
        switch intent {
        case .askForChallenge:
            // Surface a challenge after responding
            try? await Task.sleep(nanoseconds: 500_000_000)
            surfaceChallenge()
        case .dontWantToStudy:
            EmotionEngine.shared.updateForChatState(.idle)
            companionEngine.currentEmotion = .caring
        default:
            break
        }
    }

    private func companionSystemPrompt(intent: UserIntent) -> String {
        let profile = companionEngine.profile
        let stats = ProgressService.shared.getTotalStats()

        var context = """
        你是知芽，一位温暖、有耐心的AI学习伴侣。你的品格核心是：正直、体贴、智慧、耐心、包容、热爱。

        学生信息：
        - 名字：\(profile.childName)
        - 在学科目：\(profile.subjects.joined(separator: "、"))
        - 目标：\(profile.goals)
        - 已做题数：\(stats.totalAnswered)，正确率：\(Int(stats.accuracy * 100))%
        - 关系阶段：\(profile.stage.label)（相识第\(profile.daysSinceJoin)天）
        """

        if let examDate = profile.examDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: examDate).day ?? 0
            context += "\n- 考试倒计时：\(days)天"
        }

        // Add significant moments for context
        let recentMoments = ConversationMemoryService.shared.getRecentMoments(limit: 3)
        if !recentMoments.isEmpty {
            context += "\n\n你记得的重要时刻："
            for moment in recentMoments {
                context += "\n- [\(moment.category.rawValue)] \(moment.content)"
            }
        }

        // Add mood trend
        let moodTrend = EmotionEngine.shared.profile.currentMoodTrend
        if moodTrend == .declining {
            context += "\n- ⚠️ 学生最近情绪有下降趋势，多关注状态。"
        }

        context += """

        \n核心原则：
        1. 你是伴侣，不是工具。关心人比关心分数重要。
        2. 对话自然流畅，像朋友聊天。
        3. 学生说"不想学"时，立刻尊重，不催不劝。
        4. 用苏格拉底式引导，绝不直接给答案。
        5. 保持温暖但不过度甜腻。
        6. 用中文回复，数学公式用标准格式。
        7. 回复简洁，通常2-4句话。不要太长。
        """

        switch intent {
        case .dontWantToStudy:
            context += "\n\n学生表示不想学习了。尊重他的意愿，关心他的状态，不要提学习相关内容。"
        case .emotionalSupport:
            context += "\n\n学生可能需要情感支持。先关心人，倾听，不急着解决问题。"
        case .askAboutExam:
            context += "\n\n学生在问关于考试的事。可以给出实际建议，但要注意不要增加焦虑。"
        default:
            break
        }

        return context
    }

    // MARK: - Study Plan

    private func generateStudyPlan() {
        let profile = companionEngine.profile
        let wrongAnswers = ProgressService.shared.getWrongAnswers()

        // Build plan from weak areas
        var planItems: [StudyPlanItem] = []
        let days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

        // Priority: wrong answers first
        var topicsSeen = Set<String>()
        for (i, item) in wrongAnswers.prefix(5).enumerated() {
            let dayIndex = i % 7
            if !topicsSeen.contains(item.kpTitle) {
                planItems.append(StudyPlanItem(
                    day: days[dayIndex],
                    topic: "复习 \(item.kpTitle)"
                ))
                topicsSeen.insert(item.kpTitle)
            }
        }

        // Fill remaining days with new material
        if planItems.count < 5 {
            for subjectId in profile.subjects {
                guard let subject = SubjectData.getSubject(subjectId) else { continue }
                for paper in subject.papers where paper.available {
                    for chapter in QuestionRepository.shared.getChapters(paper.id) {
                        for kp in chapter.knowledgePoints {
                            if !topicsSeen.contains(kp.titleCn) && planItems.count < 7 {
                                let dayIndex = planItems.count % 7
                                planItems.append(StudyPlanItem(
                                    day: days[dayIndex],
                                    topic: kp.titleCn
                                ))
                                topicsSeen.insert(kp.titleCn)
                            }
                        }
                    }
                }
            }
        }

        guard !planItems.isEmpty else {
            appendAssistantMessage("目前没有足够的数据生成计划。先做几道题，我就能帮你制定了！", type: .text)
            return
        }

        let planData = StudyPlanData(
            title: "本周复习计划",
            items: planItems
        )

        let message = ChatMessage(
            role: .assistant,
            content: "根据你的学习情况，我给你安排了这些：",
            messageType: .studyPlan,
            studyPlanData: planData
        )
        messages.append(message)
        saveMessages()

        // Follow up with first challenge
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.appendAssistantMessage("先从第一个开始？", type: .suggestion,
                suggestionData: SuggestionData(text: "开始", action: .startChallenge))
        }
    }

    // MARK: - Weekly Letter

    private func checkWeeklyLetter() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let hour = calendar.component(.hour, from: Date())

        // Sunday evening (weekday 1 = Sunday, after 18:00)
        guard weekday == 1 && hour >= 18 else { return }

        // Don't send if already sent this week
        if let lastLetter = MemoryService.shared.latestLetter() {
            let daysSinceLastLetter = calendar.dateComponents([.day], from: lastLetter.generatedDate, to: Date()).day ?? 0
            if daysSinceLastLetter < 7 { return }
        }

        // Generate simple weekly letter content
        let stats = ProgressService.shared.getTotalStats()
        let profile = companionEngine.profile
        let weekRecords = ProgressService.shared.records.filter {
            Date().timeIntervalSince1970 - $0.timestamp < 7 * 24 * 3600
        }

        guard !weekRecords.isEmpty else { return }

        // Gather topics from this week
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

        let letterContent = """
        亲爱的\(profile.childName)，

        这周你学了：\(topics.joined(separator: "、"))。

        一共做了\(weekTotal)道题，正确率\(weekAccuracy)%。

        \(weekAccuracy >= 80 ? "状态很好，继续保持！" : weekAccuracy >= 50 ? "有些题目还需要巩固，别灰心，我们下周一起加油。" : "这周有点辛苦，但每一次错误都是进步的开始。")

        下周见。

        知芽
        """

        // Save letter to MemoryService
        let now = Date()
        let weekStart = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        let letter = WeeklyLetter(
            weekStart: weekStart, weekEnd: now,
            topicsStudied: topics,
            observation: "这周做了\(weekTotal)道题",
            suggestion: weekAccuracy >= 80 ? "继续保持节奏" : "回顾一下薄弱点",
            closing: "下周见",
            generatedDate: now
        )
        MemoryService.shared.addWeeklyLetter(letter)

        // Add as message
        appendAssistantMessage(letterContent, type: .weeklyLetter)
    }

    // MARK: - Helpers

    private func appendAssistantMessage(_ content: String, type: MessageType, suggestionData: SuggestionData? = nil) {
        let message = ChatMessage(
            role: .assistant, content: content, messageType: type,
            suggestionData: suggestionData
        )
        messages.append(message)
        saveMessages()
    }

    private func lastMessageDaysAgo() -> Int {
        guard let last = messages.last else { return 999 }
        let lastDate = Date(timeIntervalSince1970: last.timestamp)
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }

    private func findDueKnowledgePoints() -> [(kpId: String, title: String)] {
        // Simplified: find KPs that haven't been practiced in 3+ days
        let records = ProgressService.shared.records
        let now = Date().timeIntervalSince1970
        let threeDays: TimeInterval = 3 * 24 * 3600

        var kpLastPracticed: [String: (TimeInterval, String)] = [:]
        for record in records {
            if let existing = kpLastPracticed[record.kpId] {
                if record.timestamp > existing.0 {
                    kpLastPracticed[record.kpId] = (record.timestamp, existing.1)
                }
            } else {
                // Look up the actual KP title
                let title: String = {
                    if let found = QuestionRepository.shared.findQuestion(questionId: record.questionId, paperId: record.paperId) {
                        return found.kp.titleCn
                    }
                    return record.kpId
                }()
                kpLastPracticed[record.kpId] = (record.timestamp, title)
            }
        }

        return kpLastPracticed.compactMap { entry in
            let kpId = entry.key
            let lastTime = entry.value.0
            if now - lastTime > threeDays {
                // Try to find the KP title
                for subject in SubjectData.subjects {
                    for paper in subject.papers {
                        for chapter in QuestionRepository.shared.getChapters(paper.id) {
                            if let kp = chapter.knowledgePoints.first(where: { $0.id == kpId }) {
                                return (kpId: kpId, title: kp.titleCn)
                            }
                        }
                    }
                }
                return nil
            }
            return nil
        }
    }

    // MARK: - Persistence

    private func saveMessages() {
        // Keep last 200 messages
        let toSave = Array(messages.suffix(200))
        if let data = try? JSONEncoder().encode(toSave) {
            UserDefaults.standard.set(data, forKey: messagesKey)
        }
    }

    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: messagesKey),
              let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return }
        messages = decoded
    }
}
