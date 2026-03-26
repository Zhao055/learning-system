import SwiftUI

final class SettingsViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var serverURL: String = ""
    @Published var authToken: String = ""
    @Published var examDate: Date = Date()
    @Published var hasExamDate: Bool = false
    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var isTesting: Bool = false
    @Published var serverConnectionStatus: ConnectionStatus = .unknown
    @Published var isTestingServer: Bool = false
    @Published var aiMode: AIMode = .current {
        didSet { UserDefaults.standard.set(aiMode.rawValue, forKey: "zhiya_ai_mode") }
    }

    enum ConnectionStatus: Equatable {
        case unknown, testing, success, failed
    }

    func load() {
        apiKey = AIService.shared.apiKey ?? ""
        serverURL = UserDefaults.standard.string(forKey: "zhiya_server_url") ?? "http://localhost:3000"
        authToken = UserDefaults.standard.string(forKey: "zhiya_auth_token") ?? ""
        if let dateStr = UserDefaults.standard.string(forKey: "zhiya_exam_date"),
           let date = ISO8601DateFormatter().date(from: dateStr) {
            examDate = date
            hasExamDate = true
        }
    }

    func saveApiKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        AIService.shared.saveApiKey(trimmed)
    }

    func saveAuthToken() {
        let trimmed = authToken.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed, forKey: "zhiya_auth_token")
    }

    func saveServerURL() {
        UserDefaults.standard.set(serverURL, forKey: "zhiya_server_url")
        serverConnectionStatus = .success
        // Reset after 2 seconds
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if serverConnectionStatus == .success { serverConnectionStatus = .unknown }
        }
    }

    @MainActor
    func testServerConnection() {
        isTestingServer = true
        serverConnectionStatus = .testing
        Task {
            let success = await SynapseAPI.shared.testConnection()
            serverConnectionStatus = success ? .success : .failed
            isTestingServer = false
        }
    }

    func saveExamDate(companion: CompanionEngine) {
        if hasExamDate {
            let formatter = ISO8601DateFormatter()
            UserDefaults.standard.set(formatter.string(from: examDate), forKey: "zhiya_exam_date")
            companion.profile.examDate = examDate
        } else {
            UserDefaults.standard.removeObject(forKey: "zhiya_exam_date")
            companion.profile.examDate = nil
        }
    }

    @MainActor
    func testConnection() {
        isTesting = true
        connectionStatus = .testing
        Task {
            let success = await AIService.shared.testConnection()
            connectionStatus = success ? .success : .failed
            isTesting = false
        }
    }

    func clearProgress() {
        ProgressService.shared.clearAll()
    }
}
