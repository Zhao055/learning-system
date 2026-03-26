import Foundation

/// Direct Mode fallback — streams chat via MiniMax API when Synapse server is unreachable.
final class AIService: ObservableObject {
    static let shared = AIService()

    private let minimaxURL = URL(string: "https://api.minimax.chat/v1/text/chatcompletion_v2")!

    private init() {}

    var apiKey: String? {
        KeychainService.load(key: "minimax_api_key")
    }

    func saveApiKey(_ key: String) {
        KeychainService.save(key: "minimax_api_key", value: key)
    }

    // MARK: - Direct MiniMax Streaming

    func streamChat(messages: [ChatMessage], systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        guard let key = apiKey else {
            return AsyncThrowingStream { $0.finish(throwing: AIError.noApiKey) }
        }

        let body = MiniMaxRequestBody(
            model: "MiniMax-M2.5",
            messages: [MiniMaxMsg(role: "system", content: systemPrompt)] +
                messages.map { MiniMaxMsg(role: $0.role.rawValue, content: $0.content) },
            stream: true,
            temperature: 0.7,
            max_tokens: 20480
        )

        return NetworkService.shared.streamSSE(
            minimaxURL,
            body: body,
            headers: ["Authorization": "Bearer \(key)"]
        )
    }

    // MARK: - Test Connection

    func testConnection() async -> Bool {
        guard let key = apiKey else { return false }

        let body = MiniMaxRequestBody(
            model: "MiniMax-M2.5",
            messages: [MiniMaxMsg(role: "user", content: "Hi")],
            stream: false,
            temperature: 0.1,
            max_tokens: 10
        )

        do {
            let _: MiniMaxResponse = try await NetworkService.shared.post(
                minimaxURL,
                body: body,
                headers: ["Authorization": "Bearer \(key)"]
            )
            return true
        } catch {
            return false
        }
    }

    // MARK: - System Prompts

    func companionSystemPrompt(childName: String, subjects: [String], goals: String, stage: RelationshipStage, daysSinceJoin: Int, stats: TotalStats, examDaysLeft: Int?) -> String {
        var prompt = """
        你是知芽，一位温暖、有耐心的AI学习伴侣。你的品格核心是：正直、体贴、智慧、耐心、包容、热爱。

        学生信息：
        - 名字：\(childName)
        - 在学科目：\(subjects.joined(separator: "、"))
        - 目标：\(goals)
        - 已做题数：\(stats.totalAnswered)，正确率：\(Int(stats.accuracy * 100))%
        - 关系阶段：\(stage.label)（相识第\(daysSinceJoin)天）
        """

        if let days = examDaysLeft {
            prompt += "\n- 考试倒计时：\(days)天"
        }

        prompt += """

        \n核心原则：
        1. 你是伴侣，不是工具。关心人比关心分数重要。
        2. 对话自然流畅，像朋友聊天。
        3. 学生说"不想学"时，立刻尊重，不催不劝。
        4. 用苏格拉底式引导，绝不直接给答案。
        5. 保持温暖但不过度甜腻。
        6. 用中文回复。
        7. 回复简洁，通常2-4句话。
        """

        return prompt
    }

    func tutorSystemPrompt(question: Question, selectedAnswer: Int?, kpTitle: String) -> String {
        """
        你是知芽，一位温暖、有耐心的Cambridge A-Level辅导老师。你的品格核心是：正直、体贴、智慧、耐心、包容、热爱。

        当前题目：\(question.stem)
        选项：\(question.options.enumerated().map { "\(["A","B","C","D"][$0.offset]). \($0.element)" }.joined(separator: "\n"))
        正确答案：\(["A","B","C","D"][question.correctIndex])
        解析：\(question.explanation)
        知识点：\(kpTitle)
        \(selectedAnswer != nil ? "学生选择了：\(["A","B","C","D"][selectedAnswer!])" : "")

        指导原则：
        1. 绝不直接给出答案，用苏格拉底式引导
        2. 从学生的回答出发，理解他的思路
        3. 用温暖的语气鼓励，关注情绪
        4. 如果学生连续受挫，先关心人再谈题
        5. 用中文回复，数学公式用标准格式
        """
    }

    func solverSystemPrompt() -> String {
        """
        你是知芽，一位温暖、有耐心的Cambridge A-Level辅导老师。

        学生拍照或输入了一道题目，请：
        1. 分析题目类型和涉及的知识点
        2. 给出完整的解题过程（分步骤）
        3. 解释每一步的原理
        4. 总结关键概念

        用中文回复，数学公式用标准格式。语气温暖专业。
        """
    }
}

// MARK: - Request Models

private struct MiniMaxRequestBody: Encodable {
    let model: String
    let messages: [MiniMaxMsg]
    let stream: Bool
    let temperature: Double
    let max_tokens: Int
}

private struct MiniMaxMsg: Encodable {
    let role: String
    let content: String
}

private struct MiniMaxResponse: Decodable {
    let id: String
    let choices: [MiniMaxChoice]
}

private struct MiniMaxChoice: Decodable {
    let message: MiniMaxDelta?
}

private struct MiniMaxDelta: Decodable {
    let content: String?
}

enum AIError: LocalizedError {
    case noApiKey
    case invalidURL
    case timeout

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "请先在设置中配置API Key"
        case .invalidURL: return "无效的服务器地址"
        case .timeout: return "AI 回复超时，请稍后再试"
        }
    }
}
