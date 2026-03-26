import Foundation
import SwiftUI

final class CompanionEngine: ObservableObject {
    @Published var profile: CompanionProfile {
        didSet { saveProfile() }
    }
    @Published var currentEmotion: ZhiyaEmotion = .gazing

    private let profileKey = "zhiya_companion_profile"

    init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let p = try? JSONDecoder().decode(CompanionProfile.self, from: data) {
            profile = p
        } else {
            profile = CompanionProfile()
        }
    }

    // MARK: - Greeting

    func generateGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let stats = ProgressService.shared.getTotalStats()
        let stage = profile.stage

        // Time-based overrides
        if hour >= 22 {
            currentEmotion = .caring
            return "已经很晚了，\(profile.childName)。今天学够多了，早点休息吧。"
        }

        // Exam day check
        if let examDate = profile.examDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: examDate).day ?? 0
            if days == 0 {
                currentEmotion = .calm
                return "今天考试？\(profile.childName)，你准备了很多。去吧，考完来告诉我。"
            } else if days == 1 {
                currentEmotion = .calm
                return "明天就考试了。你已经准备得很好了，今晚放松一下。"
            } else if days <= 7 {
                currentEmotion = .gazing
                return "还有\(days)天考试。一步一步来，你可以的。"
            }
        }

        // Stage-based greetings
        switch stage {
        case .seed:
            currentEmotion = .gazing
            let timeGreeting = hour < 12 ? "早上好" : hour < 18 ? "下午好" : "晚上好"
            return "\(timeGreeting)，\(profile.childName)！今天想学点什么？"

        case .familiar:
            currentEmotion = .happy
            if stats.totalAnswered > 0 {
                return "\(profile.childName)，你已经做了\(stats.totalAnswered)道题了，正确率\(Int(stats.accuracy * 100))%。继续加油！"
            }
            return "又见面了，\(profile.childName)！准备好了吗？"

        case .understanding:
            currentEmotion = .happy
            // Reference specific progress
            let wrongCount = stats.wrongCount
            if wrongCount > 0 {
                return "\(profile.childName)，错题本里还有\(wrongCount)道题等着你。要不要先把它们搞定？"
            }
            return "\(profile.childName)，今天状态怎么样？"

        case .companion:
            currentEmotion = .happy
            return "\(profile.childName)，我们已经一起走过\(profile.daysSinceJoin)天了。今天想做什么？"
        }
    }

    // MARK: - Today's Suggestion

    func todaySuggestion() -> (title: String, detail: String)? {
        let stats = ProgressService.shared.getTotalStats()
        if stats.wrongCount > 3 {
            return ("复习错题", "错题本里有\(stats.wrongCount)道题，先把它们搞通？")
        }
        if stats.totalAnswered == 0 {
            return ("开始第一道题", "选一个科目，从第一章开始吧！")
        }
        return ("继续学习", "保持节奏，每天进步一点点。")
    }

    // MARK: - Struggle Detection

    func onConsecutiveWrong(_ count: Int) {
        if count >= 3 {
            currentEmotion = .caring
        }
    }

    // MARK: - 热爱品格：偶尔关心生活

    /// 生成一个非学习的关心语句（热爱品格：不只是分数）
    func lifeCareMessage() -> String? {
        let hour = Calendar.current.component(.hour, from: Date())

        // 21:00+ 关心作息
        if hour >= 21 {
            return "最近睡得好不好？学习很重要，但休息也是成长的一部分。"
        }

        // 引用记忆中的生活事件
        let moments = ConversationMemoryService.shared.getMoments(category: .lifeEvent)
        if let recent = moments.last {
            let daysAgo = Calendar.current.dateComponents([.day], from: recent.timestamp, to: Date()).day ?? 0
            if daysAgo <= 3 && daysAgo >= 1 {
                return "之前提到的事情怎么样了？"
            }
        }

        return nil
    }

    // MARK: - Last Active Tracking

    func recordActivity() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "zhiya_last_active")
    }

    func daysSinceLastActive() -> Int {
        let lastActive = UserDefaults.standard.double(forKey: "zhiya_last_active")
        guard lastActive > 0 else { return 0 }
        let lastDate = Date(timeIntervalSince1970: lastActive)
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }

    // MARK: - Persistence

    func setupProfile(name: String, subjects: [String], goals: String) {
        profile.childName = name
        profile.subjects = subjects
        profile.goals = goals
        profile.joinDate = Date()
        saveProfile()
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
}
