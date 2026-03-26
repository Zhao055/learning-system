import Foundation

enum AIMode: String, CaseIterable {
    case auto = "auto"
    case server = "server"
    case direct = "direct"

    var label: String {
        switch self {
        case .auto: return "自动"
        case .server: return "服务器"
        case .direct: return "SDK 直连"
        }
    }

    var description: String {
        switch self {
        case .auto: return "自动选择：优先服务器，回退到 SDK 直连"
        case .server: return "仅使用 Synapse 服务器"
        case .direct: return "仅使用 MiniMax SDK 直连"
        }
    }

    static var current: AIMode {
        AIMode(rawValue: UserDefaults.standard.string(forKey: "zhiya_ai_mode") ?? "auto") ?? .auto
    }
}
