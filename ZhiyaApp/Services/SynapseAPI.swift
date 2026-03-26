import Foundation
import UIKit

/// Server Mode — talks to zhiya-server /api/chat/tutor.
actor SynapseAPI {
    static let shared = SynapseAPI()

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 90
        #if targetEnvironment(simulator)
        config.connectionProxyDictionary = [:]
        #endif
        return URLSession(configuration: config)
    }()

    private var serverURL: String {
        UserDefaults.standard.string(forKey: "zhiya_server_url") ?? ""
    }

    private var authToken: String? {
        UserDefaults.standard.string(forKey: "zhiya_auth_token")
    }

    // MARK: - Chat (non-streaming)

    func chat(messages: [[String: String]], personaId: String) async throws -> AgentResult {
        guard !serverURL.isEmpty else { throw APIError.notConfigured }

        let lastUserMessage = messages.last(where: { $0["role"] == "user" })?["content"] ?? ""

        let body: [String: Any] = [
            "message": lastUserMessage,
            "sessionId": "zhiya-ios-\(personaId)"
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        guard let chatURL = URL(string: "\(serverURL)/api/chat/tutor") else { throw APIError.notConfigured }
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = jsonData

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw APIError.http((response as? HTTPURLResponse)?.statusCode ?? 0, msg)
        }

        let agentResponse = try JSONDecoder().decode(AgentResponse.self, from: data)

        if let approval = agentResponse.pendingApprovals?.first {
            return .approval(text: agentResponse.text, approval: approval)
        }
        return .text(agentResponse.text)
    }

    // MARK: - Chat (streaming via SSE)

    /// Returns an AsyncThrowingStream that yields text chunks from the server.
    /// Captures all needed state upfront to avoid actor reentrancy issues.
    func chatStream(messages: [[String: String]], personaId: String) async -> AsyncThrowingStream<String, Error> {
        // Capture everything we need from the actor before returning the stream
        let url = serverURL
        let token = authToken
        let session = urlSession

        guard !url.isEmpty else {
            return AsyncThrowingStream { $0.finish(throwing: APIError.notConfigured) }
        }

        let lastUserMessage = messages.last(where: { $0["role"] == "user" })?["content"] ?? ""
        let contextMessages = messages.filter { $0["role"] != "system" }

        let body: [String: Any] = [
            "message": lastUserMessage,
            "sessionId": "zhiya-ios-\(personaId)",
            "context": ["history": contextMessages]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return AsyncThrowingStream { $0.finish(throwing: APIError.notConfigured) }
        }

        guard let chatURL = URL(string: "\(url)/api/chat/tutor") else {
            return AsyncThrowingStream { $0.finish(throwing: APIError.notConfigured) }
        }
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = jsonData

        // The request is fully built — now create the stream outside actor isolation
        let capturedRequest = request
        let capturedSession = session

        return AsyncThrowingStream { continuation in
            Task.detached {
                do {
                    let (bytes, response) = try await capturedSession.bytes(for: capturedRequest)
                    guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                        continuation.finish(throwing: APIError.http(
                            (response as? HTTPURLResponse)?.statusCode ?? 0, "Stream failed"
                        ))
                        return
                    }

                    var hasReceivedContent = false
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            if data == "[DONE]" { break }

                            guard let jd = data.data(using: .utf8),
                                  let parsed = try? JSONSerialization.jsonObject(with: jd) as? [String: Any] else { continue }

                            if let text = parsed["text"] as? String, !text.isEmpty {
                                continuation.yield(text)
                                hasReceivedContent = true
                            } else if let choices = parsed["choices"] as? [[String: Any]],
                                      let first = choices.first {
                                if let delta = first["delta"] as? [String: Any],
                                   let content = delta["content"] as? String, !content.isEmpty {
                                    continuation.yield(content)
                                    hasReceivedContent = true
                                } else if !hasReceivedContent,
                                          let message = first["message"] as? [String: Any],
                                          let content = message["content"] as? String, !content.isEmpty {
                                    continuation.yield(content)
                                    hasReceivedContent = true
                                }
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

    // MARK: - Test Connection & Auto-register

    func testConnection() async -> Bool {
        guard !serverURL.isEmpty,
              let healthURL = URL(string: "\(serverURL)/health") else { return false }

        do {
            var healthReq = URLRequest(url: healthURL)
            healthReq.timeoutInterval = 10
            let (_, healthResp) = try await urlSession.data(for: healthReq)
            guard (healthResp as? HTTPURLResponse)?.statusCode == 200 else { return false }

            await ensureAuthToken()

            guard let token = UserDefaults.standard.string(forKey: "zhiya_auth_token"), !token.isEmpty,
                  let greetingURL = URL(string: "\(serverURL)/api/companion/greeting") else { return false }
            var authReq = URLRequest(url: greetingURL)
            authReq.timeoutInterval = 10
            authReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (_, authResp) = try await urlSession.data(for: authReq)
            return (authResp as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    private func ensureAuthToken() async {
        if let existing = UserDefaults.standard.string(forKey: "zhiya_auth_token"), !existing.isEmpty {
            return
        }

        do {
            let deviceId = await MainActor.run { UIDevice.current.identifierForVendor?.uuidString } ?? UUID().uuidString
            let body: [String: Any] = [
                "deviceId": deviceId,
                "name": ""
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: body)

            guard let registerURL = URL(string: "\(serverURL)/auth/register") else { return }
            var request = URLRequest(url: registerURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10
            request.httpBody = jsonData

            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["token"] as? String {
                UserDefaults.standard.set(token, forKey: "zhiya_auth_token")
            }
        } catch {}
    }

    // MARK: - Errors

    enum APIError: LocalizedError {
        case notConfigured
        case http(Int, String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "服务器未配置"
            case .http(let code, let msg): return "HTTP \(code): \(msg)"
            }
        }
    }
}

// MARK: - Response Types

struct AgentResponse: Decodable {
    let text: String
    let pendingApprovals: [PendingApproval]?
}

struct PendingApproval: Decodable {
    let id: String
    let description: String
}

enum AgentResult {
    case text(String)
    case approval(text: String, approval: PendingApproval)

    var textContent: String {
        switch self {
        case .text(let t): return t
        case .approval(let t, _): return t
        }
    }
}
