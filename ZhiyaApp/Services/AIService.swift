import Foundation

final class AIService: ObservableObject {
    static let shared = AIService()

    private let minimaxURL = URL(string: "https://api.minimax.chat/v1/text/chatcompletion_v2")!
    private var serverBaseURL: String {
        UserDefaults.standard.string(forKey: "zhiya_server_url") ?? "http://localhost:3000"
    }

    private init() {}

    var apiKey: String? {
        KeychainService.load(key: "minimax_api_key")
    }

    func saveApiKey(_ key: String) {
        KeychainService.save(key: "minimax_api_key", value: key)
    }

    // MARK: - Direct MiniMax

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

    // MARK: - Server Gateway

    func streamChatViaServer(sessionId: String, message: String, context: [String: Any] = [:]) -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: "\(serverBaseURL)/api/chat/tutor") else {
            return AsyncThrowingStream { $0.finish(throwing: AIError.invalidURL) }
        }

        let body = ServerChatRequest(sessionId: sessionId, message: message, context: context)
        return NetworkService.shared.streamSSE(url, body: body)
    }

    // MARK: - Synapse Gateway

    /// Stream chat via zhiya-server's Synapse bridge. Returns both text chunks and structured events.
    func streamChatViaSynapse(sessionId: String, message: String, context: [String: Any] = [:]) -> AsyncThrowingStream<SynapseEvent, Error> {
        guard let url = URL(string: "\(serverBaseURL)/api/synapse/chat") else {
            return AsyncThrowingStream { $0.finish(throwing: AIError.invalidURL) }
        }

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    // Add auth token if available
                    if let token = UserDefaults.standard.string(forKey: "zhiya_auth_token") {
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    }

                    let body: [String: Any] = [
                        "sessionId": sessionId,
                        "message": message,
                        "context": context
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                        continuation.finish(throwing: NetworkError.badStatus((response as? HTTPURLResponse)?.statusCode ?? 0))
                        return
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            if data == "[DONE]" { break }

                            guard let jsonData = data.data(using: .utf8),
                                  let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { continue }

                            if let type = parsed["type"] as? String {
                                switch type {
                                case "tool_call":
                                    let toolName = parsed["name"] as? String ?? ""
                                    let args = parsed["arguments"] as? [String: Any] ?? [:]
                                    continuation.yield(.toolCall(name: toolName, arguments: args))

                                case "tool_result":
                                    let toolName = parsed["name"] as? String ?? ""
                                    let result = parsed["result"] as? [String: Any] ?? [:]
                                    continuation.yield(.toolResult(name: toolName, result: result))

                                default:
                                    // Try to extract text content
                                    if let text = parsed["text"] as? String {
                                        continuation.yield(.text(text))
                                    }
                                }
                            } else if let choices = parsed["choices"] as? [[String: Any]],
                                      let delta = choices.first?["delta"] as? [String: Any],
                                      let content = delta["content"] as? String {
                                continuation.yield(.text(content))
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Whether Synapse mode is available (server URL configured)
    var isSynapseAvailable: Bool {
        UserDefaults.standard.bool(forKey: "zhiya_synapse_enabled")
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

    // MARK: - Tutor System Prompt

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

private struct ServerChatRequest: Encodable {
    let sessionId: String
    let message: String
    let context: [String: Any]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(message, forKey: .message)
        // context is encoded as empty object for simplicity
    }

    enum CodingKeys: String, CodingKey {
        case sessionId, message, context
    }
}

enum AIError: LocalizedError {
    case noApiKey
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "请先在设置中配置API Key"
        case .invalidURL: return "无效的服务器地址"
        }
    }
}

// MARK: - Synapse Event Types

/// Events received from Synapse SSE stream
enum SynapseEvent {
    /// Text content chunk for streaming display
    case text(String)
    /// Agent called a tool (e.g., zhiya_get_random_question → show ChallengeCard)
    case toolCall(name: String, arguments: [String: Any])
    /// Tool execution result
    case toolResult(name: String, result: [String: Any])
}
