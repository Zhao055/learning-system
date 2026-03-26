import Foundation

final class NetworkService {
    static let shared = NetworkService()
    private init() {}

    func post<T: Decodable>(_ url: URL, body: Encodable, headers: [String: String] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NetworkError.badStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Timeout-aware URLSession for streaming (30s connect, 60s resource)
    private lazy var streamSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    func streamSSE(_ url: URL, body: Encodable, headers: [String: String] = [:]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    for (key, value) in headers {
                        request.setValue(value, forHTTPHeaderField: key)
                    }
                    request.httpBody = try JSONEncoder().encode(body)
                    request.timeoutInterval = 30

                    let (bytes, response) = try await streamSession.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                        continuation.finish(throwing: NetworkError.badStatus((response as? HTTPURLResponse)?.statusCode ?? 0))
                        return
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            if data == "[DONE]" { break }
                            if let jsonData = data.data(using: .utf8),
                               let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let choices = parsed["choices"] as? [[String: Any]],
                               let delta = choices.first?["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                continuation.yield(content)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func get<T: Decodable>(_ url: URL, headers: [String: String] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NetworkError.badStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum NetworkError: LocalizedError {
    case badStatus(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "Server error: \(code)"
        case .invalidResponse: return "Invalid response"
        }
    }
}
