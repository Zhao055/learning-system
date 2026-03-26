import Foundation

final class ConversationMemoryService {
    static let shared = ConversationMemoryService()

    private let significantMomentsKey = "zhiya_significant_moments"

    private init() {}

    struct SignificantMoment: Codable, Identifiable {
        let id: String
        let content: String
        let category: MomentCategory
        let timestamp: Date
        let emotionalWeight: Double

        init(id: String = UUID().uuidString, content: String, category: MomentCategory, timestamp: Date = Date(), emotionalWeight: Double = 0.5) {
            self.id = id
            self.content = content
            self.category = category
            self.timestamp = timestamp
            self.emotionalWeight = emotionalWeight
        }
    }

    enum MomentCategory: String, Codable {
        case breakthrough   // "我终于懂了！"
        case frustration    // "我不行了"
        case dream          // "我想上剑桥"
        case joy            // "我考了A*!"
        case connection     // Deep conversation with Zhiya
        case preference     // "我喜欢..." / "我不喜欢..."
        case lifeEvent      // "今天考试" / "生日" / 生活事件
    }

    // MARK: - Extract & Store

    /// Analyze a message for significant moments worth remembering
    func analyzeAndStore(message: ChatMessage) {
        guard message.role == .user else { return }
        let text = message.content.lowercased()

        // Simple keyword-based extraction (in production, AI would do this)
        if text.contains("终于懂了") || text.contains("明白了") || text.contains("原来如此") {
            storeMoment(SignificantMoment(
                content: message.content,
                category: .breakthrough,
                emotionalWeight: 0.8
            ))
            // Also create a growth memory
            MemoryService.shared.addMemory(GrowthMemory(
                type: .academicBreakthrough,
                title: "学习突破",
                content: message.content,
                dimension: .academic,
                emotionalWeight: 0.8
            ))
        }

        if text.contains("不行") || text.contains("太难") || text.contains("放弃") {
            storeMoment(SignificantMoment(
                content: message.content,
                category: .frustration,
                emotionalWeight: 0.7
            ))
        }

        if text.contains("想上") || text.contains("梦想") || text.contains("将来") || text.contains("以后想") || text.contains("想当") || text.contains("想成为") {
            storeMoment(SignificantMoment(
                content: message.content,
                category: .dream,
                emotionalWeight: 0.9
            ))
            MemoryService.shared.addMemory(GrowthMemory(
                type: .dream,
                title: "梦想",
                content: message.content,
                dimension: .lifeExploration,
                emotionalWeight: 0.9
            ))
        }

        // 生活事件
        if text.contains("考试") || text.contains("生日") || text.contains("比赛") || text.contains("生病") {
            storeMoment(SignificantMoment(
                content: message.content,
                category: .lifeEvent,
                emotionalWeight: 0.6
            ))
        }

        // 喜好记忆 — 热爱品格：记得孩子的喜好
        if text.contains("喜欢") || text.contains("最爱") || text.contains("讨厌") || text.contains("不喜欢") {
            storeMoment(SignificantMoment(
                content: message.content,
                category: .preference,
                emotionalWeight: 0.5
            ))
        }

        // 开心时刻
        if text.contains("开心") || text.contains("高兴") || text.contains("太好了") || text.contains("考了") {
            storeMoment(SignificantMoment(
                content: message.content,
                category: .joy,
                emotionalWeight: 0.7
            ))
        }
    }

    // MARK: - Retrieve

    func getMoments(category: MomentCategory? = nil) -> [SignificantMoment] {
        let all = loadMoments()
        if let category = category {
            return all.filter { $0.category == category }
        }
        return all
    }

    func getRecentMoments(limit: Int = 10) -> [SignificantMoment] {
        Array(loadMoments().sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }

    // MARK: - Persistence

    func storeMoment(_ moment: SignificantMoment) {
        var moments = loadMoments()
        moments.append(moment)
        // Keep last 500 moments
        if moments.count > 500 {
            moments = Array(moments.suffix(500))
        }
        saveMoments(moments)
    }

    private func loadMoments() -> [SignificantMoment] {
        guard let data = UserDefaults.standard.data(forKey: significantMomentsKey),
              let decoded = try? JSONDecoder().decode([SignificantMoment].self, from: data) else { return [] }
        return decoded
    }

    private func saveMoments(_ moments: [SignificantMoment]) {
        if let data = try? JSONEncoder().encode(moments) {
            UserDefaults.standard.set(data, forKey: significantMomentsKey)
        }
    }
}
