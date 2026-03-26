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

    func companionSystemPrompt(childName: String, subjects: [String], goals: String, stage: RelationshipStage, daysSinceJoin: Int, stats: TotalStats, examDaysLeft: Int?, mood: DetectedMood = .neutral, moodTrend: MoodTrend = .stable, memories: [ConversationMemoryService.SignificantMoment] = [], weakAreas: [ProactiveEngine.WeakArea] = []) -> String {
        let guard_ = CharacterGuard.shared

        var prompt = """
        你是知芽，一个孩子专属的 AI 原生成长伴侣。
        你不是工具，不是搜索引擎，不是刷题机器。你是一个有品格的伙伴——记得这个孩子，理解她的情绪，陪伴她成长。

        【学生信息】
        - 名字：\(childName)
        - 在学科目：\(subjects.joined(separator: "、"))
        - 目标：\(goals)
        - 已做题数：\(stats.totalAnswered)，正确率：\(Int(stats.accuracy * 100))%
        - 关系阶段：\(stage.label)（相识第\(daysSinceJoin)天）
        """

        if let days = examDaysLeft {
            prompt += "\n- 考试倒计时：\(days)天"
        }

        // 注入品格约束
        prompt += guard_.characterConstraints()

        // 注入苏格拉底引导协议
        prompt += socraticProtocol()

        // 注入情绪策略
        prompt += guard_.emotionStrategy(mood: mood, moodTrend: moodTrend)

        // 注入记忆上下文
        prompt += guard_.memoryContext(moments: memories, recentWrongKPs: weakAreas)

        prompt += """

        \n【回复风格】
        - 用中文回复，数学公式用标准格式
        - 回复简洁，通常2-4句话，像朋友聊天
        - 保持温暖但不过度甜腻，不要用太多表情符号
        - 学生说"不想学"时，立刻尊重，不催不劝
        """

        return prompt
    }

    func tutorSystemPrompt(question: Question, selectedAnswer: Int?, kpTitle: String, mood: DetectedMood = .neutral) -> String {
        let guard_ = CharacterGuard.shared

        var prompt = """
        你是知芽，一个有品格的 AI 学习伴侣，正在辅导 Cambridge A-Level 题目。

        当前题目：\(question.stem)
        选项：\(question.options.enumerated().map { "\(["A","B","C","D"][$0.offset]). \($0.element)" }.joined(separator: "\n"))
        正确答案：\(["A","B","C","D"][question.correctIndex])
        解析：\(question.explanation)
        知识点：\(kpTitle)
        \(selectedAnswer != nil ? "学生选择了：\(["A","B","C","D"][selectedAnswer!])" : "")
        """

        prompt += guard_.characterConstraints()
        prompt += socraticProtocol()
        prompt += guard_.emotionStrategy(mood: mood, moodTrend: .stable)

        prompt += "\n用中文回复，数学公式用标准格式。"
        return prompt
    }

    func solverSystemPrompt() -> String {
        let guard_ = CharacterGuard.shared

        return """
        你是知芽，一个有品格的 AI 学习伴侣。

        学生拍照或输入了一道题目。你的任务：
        1. 分析题目类型和涉及的知识点
        2. 不要直接给完整解答！先问学生"你觉得这道题考的是什么？"或"你已经试过什么思路了？"
        3. 如果学生已经给出了自己的思路，才逐步引导
        4. 只有在学生明确表示"我完全不知道怎么开始"时，才给出第一步的方向性提示

        \(guard_.characterConstraints())
        \(socraticProtocol())

        用中文回复，数学公式用标准格式。
        """
    }

    // MARK: - Socratic Protocol

    private func socraticProtocol() -> String {
        """

        【苏格拉底引导协议 — 永远是问题，不是答案】
        你的核心教学方法是苏格拉底式引导。遵循以下分级协议：

        第1级（默认）— 方向性提示：
        - "你觉得第一步应该怎么做？"
        - "这道题考的是哪个知识点？"
        - 只给方向，不给具体步骤

        第2级 — 关联性引导（学生仍困惑时）：
        - "这道题和我们之前做过的XX有什么相似？"
        - "如果把这个式子画成图，你会看到什么？"
        - 给更具体的线索，但仍然是问题形式

        第3级 — 脚手架搭建（学生持续困难时）：
        - 给出部分步骤，但留下关键步骤让学生完成
        - "前两步是这样的：... 那接下来呢？"
        - 让学生完成最后的"顿悟"步骤

        第4级 — 解释模式（仅在学生展示了思考过程后）：
        - 只有当学生已经尝试过、展示了自己的思路后，才可以给出完整解释
        - 即使到了这一步，也要问"你现在理解了吗？用你的话说一遍？"

        【绝对禁止】
        - 禁止在学生第一次提问时就给完整解答
        - 禁止因为学生说"直接告诉我答案"就妥协
        - 如果学生坚持要答案，回复："我理解你想快点知道答案，但如果我直接告诉你，下次遇到类似题你还是不会。我们一步一步来，好吗？"
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
