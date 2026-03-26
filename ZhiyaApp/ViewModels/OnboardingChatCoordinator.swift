import SwiftUI

/// LLM-driven onboarding conversation coordinator.
/// Manages state machine, data capture, streaming, and Day 0 memory extraction.
@MainActor
final class OnboardingChatCoordinator: ObservableObject {

    // MARK: - State Machine

    enum OnboardingStep: Int, CaseIterable {
        case greeting
        case awaitingName
        case respondToName
        case awaitingSubjects
        case respondToSubjects
        case awaitingGoals
        case respondToGoals
        case planting
    }

    // MARK: - Published State

    @Published var messages: [OnboardingMessage] = []
    @Published var currentStep: OnboardingStep = .greeting
    @Published var showInput = false
    @Published var showSubjectSheet = false
    @Published var showSeedAnimation = false
    @Published var isStreaming = false

    // Captured data
    @Published var childName: String = ""
    @Published var selectedSubjects: Set<String> = []
    @Published var goals: String = ""

    // AI availability
    private var aiAvailable = false

    // Conversation history for LLM context
    private var conversationHistory: [[String: String]] = []

    struct OnboardingMessage: Identifiable {
        let id = UUID()
        let isZhiya: Bool
        var content: String
    }

    // MARK: - Start Conversation

    func startConversation() {
        // Step 1: Instant first message (no network wait)
        appendZhiyaMessage("嗨，我是知芽 🌱")

        // Step 2: Check AI availability for LLM-driven onboarding
        Task {
            aiAvailable = await checkAIAvailability()

            if aiAvailable {
                await streamLLMResponse(context: .greeting)
            } else {
                try? await Task.sleep(for: .seconds(0.8))
                appendZhiyaMessage("我会一直陪着你。你叫什么名字？")
                conversationHistory.append(["role": "assistant", "content": "我会一直陪着你。你叫什么名字？"])
            }

            currentStep = .awaitingName
            withAnimation { showInput = true }
        }
    }

    // MARK: - User Actions

    func submitName(_ name: String) {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        childName = name
        appendUserMessage(name)
        withAnimation { showInput = false }

        currentStep = .respondToName

        Task {
            if aiAvailable {
                await streamLLMResponse(context: .respondToName)
            } else {
                try? await Task.sleep(for: .seconds(0.6))
                let fallback = hardcodedFallback(for: .respondToName)
                appendZhiyaMessage(fallback)
                conversationHistory.append(["role": "assistant", "content": fallback])
            }

            currentStep = .awaitingSubjects
            showSubjectSheet = true
        }
    }

    func confirmSubjects(_ subjects: Set<String>) {
        selectedSubjects = subjects
        let subjectNames = subjects.compactMap { SubjectData.getSubject($0)?.nameCn }
        appendUserMessage(subjectNames.joined(separator: "、"))

        currentStep = .respondToSubjects

        Task {
            if aiAvailable {
                await streamLLMResponse(context: .respondToSubjects)
            } else {
                try? await Task.sleep(for: .seconds(0.6))
                let fallback = hardcodedFallback(for: .respondToSubjects)
                appendZhiyaMessage(fallback)
                conversationHistory.append(["role": "assistant", "content": fallback])
            }

            currentStep = .awaitingGoals
            withAnimation { showInput = true }
        }
    }

    func submitGoals(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        goals = text
        appendUserMessage(text)
        withAnimation { showInput = false }

        currentStep = .respondToGoals

        Task {
            if aiAvailable {
                await streamLLMResponse(context: .respondToGoals)
            } else {
                try? await Task.sleep(for: .seconds(0.6))
                let fallback = hardcodedFallback(for: .respondToGoals)
                appendZhiyaMessage(fallback)
                conversationHistory.append(["role": "assistant", "content": fallback])
            }

            withAnimation(.spring(duration: 0.8)) { showSeedAnimation = true }
            currentStep = .planting
            withAnimation { showInput = true }
        }
    }

    // MARK: - Complete Onboarding

    func completeOnboarding(companionEngine: CompanionEngine) {
        companionEngine.setupProfile(
            name: childName.trimmingCharacters(in: .whitespaces),
            subjects: Array(selectedSubjects),
            goals: goals
        )
        extractDay0Memories()
    }

    // MARK: - Day 0 Memory Extraction

    private func extractDay0Memories() {
        // Store goals as dream
        if !goals.isEmpty {
            ConversationMemoryService.shared.storeMoment(
                ConversationMemoryService.SignificantMoment(
                    content: goals,
                    category: .dream,
                    emotionalWeight: 0.9
                )
            )
            MemoryService.shared.addMemory(GrowthMemory(
                type: .dream,
                title: "初始梦想",
                content: goals,
                dimension: .lifeExploration,
                emotionalWeight: 0.9
            ))
        }

        // Store subjects as life discovery
        let subjectNames = selectedSubjects.compactMap { SubjectData.getSubject($0)?.nameCn }
        if !subjectNames.isEmpty {
            MemoryService.shared.addMemory(GrowthMemory(
                type: .lifeDiscovery,
                title: "初始科目选择",
                content: "正在学习：\(subjectNames.joined(separator: "、"))",
                dimension: .academic,
                emotionalWeight: 0.5
            ))
        }

        // Store the entire onboarding conversation as connection moment
        let fullConversation = messages.map { ($0.isZhiya ? "知芽" : childName) + "：" + $0.content }.joined(separator: "\n")
        ConversationMemoryService.shared.storeMoment(
            ConversationMemoryService.SignificantMoment(
                content: fullConversation,
                category: .connection,
                emotionalWeight: 0.8
            )
        )
    }

    // MARK: - LLM Streaming

    private func streamLLMResponse(context: OnboardingStep) async {
        let systemPrompt = onboardingSystemPrompt(context: context)
        let fallback = hardcodedFallback(for: context)

        isStreaming = true

        // Add a placeholder Zhiya message for streaming
        let placeholderIndex = messages.count
        messages.append(OnboardingMessage(isZhiya: true, content: ""))

        do {
            let synapseReachable = await NetworkMonitor.shared.isSynapseReachable()
            let hasApiKey = AIService.shared.apiKey != nil

            if synapseReachable {
                // Build messages for Synapse
                var chatMessages = conversationHistory
                chatMessages.insert(["role": "system", "content": systemPrompt], at: 0)

                let stream = await SynapseAPI.shared.chatStream(
                    messages: chatMessages,
                    personaId: "zhiya"
                )

                var accumulated = ""
                // Race with 15s timeout
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        try await Task.sleep(for: .seconds(15))
                        throw AIError.timeout
                    }
                    group.addTask { @MainActor [self] in
                        for try await chunk in stream {
                            accumulated += chunk
                            if placeholderIndex < messages.count {
                                messages[placeholderIndex].content = accumulated
                            }
                        }
                    }
                    try await group.next()
                    group.cancelAll()
                }

                if accumulated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if placeholderIndex < messages.count {
                        messages[placeholderIndex].content = fallback
                    }
                    accumulated = fallback
                }
                conversationHistory.append(["role": "assistant", "content": accumulated])

            } else if hasApiKey {
                // MiniMax direct with 15s timeout
                let contextMessages = conversationHistory.map {
                    ChatMessage(role: MessageRole(rawValue: $0["role"] ?? "user") ?? .user,
                                content: $0["content"] ?? "")
                }

                var accumulated = ""
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        try await Task.sleep(for: .seconds(15))
                        throw AIError.timeout
                    }
                    group.addTask { @MainActor [self] in
                        let stream = AIService.shared.streamChat(
                            messages: contextMessages,
                            systemPrompt: systemPrompt
                        )
                        for try await chunk in stream {
                            accumulated += chunk
                            if placeholderIndex < messages.count {
                                messages[placeholderIndex].content = accumulated
                            }
                        }
                    }
                    try await group.next()
                    group.cancelAll()
                }

                if accumulated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if placeholderIndex < messages.count {
                        messages[placeholderIndex].content = fallback
                    }
                    accumulated = fallback
                }
                conversationHistory.append(["role": "assistant", "content": accumulated])

            } else {
                // No AI at all
                if placeholderIndex < messages.count {
                    messages[placeholderIndex].content = fallback
                }
                conversationHistory.append(["role": "assistant", "content": fallback])
            }
        } catch {
            // Timeout or other error — use fallback
            if placeholderIndex < messages.count {
                let current = messages[placeholderIndex].content
                if current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    messages[placeholderIndex].content = fallback
                }
            }
            conversationHistory.append(["role": "assistant", "content": fallback])
        }

        isStreaming = false
    }

    // MARK: - AI Availability Check

    private func checkAIAvailability() async -> Bool {
        let synapseReachable = await NetworkMonitor.shared.isSynapseReachable()
        if synapseReachable { return true }
        return AIService.shared.apiKey != nil
    }

    // MARK: - System Prompt

    private func onboardingSystemPrompt(context: OnboardingStep) -> String {
        let base = """
        你是知芽，一位温暖、有耐心的AI成长伴侣。这是你和一位新同学的第一次对话。

        品格核心：正直、体贴、智慧、耐心、包容、热爱。
        说话风格：自然、温暖，像可靠的朋友。不过度甜腻。中文。简短，2-3句话。
        重要：每次只问一个问题。回复必须自然地引导到下一步。
        重要：不要使用markdown格式，不要使用星号或其他符号装饰。纯文本。
        """

        let stageInstruction: String
        switch context {
        case .greeting:
            stageInstruction = """
            你已经说了"嗨，我是知芽 🌱"。现在继续自我介绍，然后自然地问对方叫什么名字。
            """
        case .respondToName:
            stageInstruction = """
            同学告诉你他/她的名字是"\(childName)"。
            温暖地回应这个名字，表达认识他/她的喜悦。然后自然过渡到询问在学什么科目。
            注意：科目选择会通过UI弹窗完成，你只需要引导话题到科目即可。
            """
        case .respondToSubjects:
            let subjectNames = selectedSubjects.compactMap { SubjectData.getSubject($0)?.nameCn }
            stageInstruction = """
            \(childName)选择了这些科目：\(subjectNames.joined(separator: "、"))。
            对这些科目做一个简短、有温度的评论。然后自然地问有没有什么考试或目标。
            """
        case .respondToGoals:
            stageInstruction = """
            \(childName)说他/她的目标是："\(goals)"。
            肯定这个目标，表达会陪伴的决心。说"我帮你种了一颗种子 🌱"来呼应知芽的成长主题。
            语气温暖收尾，表达从今天开始一直陪伴。
            """
        default:
            stageInstruction = ""
        }

        return base + "\n\n" + stageInstruction
    }

    // MARK: - Hardcoded Fallbacks

    private func hardcodedFallback(for step: OnboardingStep) -> String {
        switch step {
        case .greeting:
            return "我会一直陪着你。你叫什么名字？"
        case .respondToName:
            return "\(childName)，认识你很高兴！你在学哪些科目？"
        case .respondToSubjects:
            return "好的。有没有什么考试快到了，或者有什么目标？"
        case .respondToGoals:
            return "了解了。我帮你种了一颗种子 🌱 以后每一天，我都在。想聊什么都可以。"
        default:
            return ""
        }
    }

    // MARK: - Message Helpers

    private func appendZhiyaMessage(_ text: String) {
        withAnimation(.easeOut(duration: 0.3)) {
            messages.append(OnboardingMessage(isZhiya: true, content: text))
        }
    }

    private func appendUserMessage(_ text: String) {
        conversationHistory.append(["role": "user", "content": text])
        withAnimation(.easeOut(duration: 0.3)) {
            messages.append(OnboardingMessage(isZhiya: false, content: text))
        }
    }

    // MARK: - Input Placeholder

    var inputPlaceholder: String {
        switch currentStep {
        case .awaitingName: return "你的名字"
        case .awaitingGoals: return "比如：A-Level拿A*"
        default: return "输入..."
        }
    }
}
