import Foundation
import UserNotifications

/// Polls zhiya-server for Synapse proactive messages and presents them as local notifications + chat messages.
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var pendingMessages: [ProactiveMessage] = []

    private var pollTimer: Timer?
    private let pollInterval: TimeInterval = 60 // Check every minute
    private var lastCheckTime: Date = Date()

    private var serverBaseURL: String {
        UserDefaults.standard.string(forKey: "zhiya_server_url") ?? "http://localhost:3000"
    }

    private init() {}

    // MARK: - Proactive Message Model

    struct ProactiveMessage: Identifiable, Codable {
        let id: String
        let type: String // morning_greeting, weekly_letter, review_reminder, evening_reflection
        let title: String
        let body: String
        let createdAt: String

        var messageType: MessageType {
            switch type {
            case "weekly_letter": return .weeklyLetter
            default: return .text
            }
        }
    }

    // MARK: - Setup

    /// Request notification permissions and start polling
    func setup() {
        requestPermissions()
        startPolling()
    }

    private func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("[NotificationService] Permission granted")
            }
            if let error = error {
                print("[NotificationService] Permission error: \(error)")
            }
        }
    }

    // MARK: - Polling

    func startPolling() {
        guard UserDefaults.standard.bool(forKey: "zhiya_synapse_enabled") else { return }

        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForNotifications()
        }
        // Initial check
        checkForNotifications()
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func checkForNotifications() {
        guard let token = UserDefaults.standard.string(forKey: "zhiya_auth_token"),
              let url = URL(string: "\(serverBaseURL)/api/synapse/notifications?since=\(lastCheckTime.ISO8601Format())") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else { return }

            do {
                let result = try JSONDecoder().decode(NotificationResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.handleNotifications(result.notifications)
                    self?.lastCheckTime = Date()
                }
            } catch {
                print("[NotificationService] Decode error: \(error)")
            }
        }.resume()
    }

    private struct NotificationResponse: Codable {
        let notifications: [ProactiveMessage]
    }

    // MARK: - Handle Notifications

    private func handleNotifications(_ notifications: [ProactiveMessage]) {
        for notification in notifications {
            // Add to pending messages for the chat view
            pendingMessages.append(notification)

            // Show local notification if app is in background
            scheduleLocalNotification(notification)
        }
    }

    private func scheduleLocalNotification(_ message: ProactiveMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.userInfo = [
            "type": message.type,
            "messageId": message.id
        ]

        let request = UNNotificationRequest(
            identifier: message.id,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Consume Messages

    /// Get and clear pending proactive messages (called by CompanionViewModel)
    func consumePendingMessages() -> [ProactiveMessage] {
        let messages = pendingMessages
        pendingMessages.removeAll()
        return messages
    }

    // MARK: - Device Token Registration

    func registerDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()

        guard let url = URL(string: "\(serverBaseURL)/api/device-token"),
              let authToken = UserDefaults.standard.string(forKey: "zhiya_auth_token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["token": token])

        URLSession.shared.dataTask(with: request).resume()
    }
}
