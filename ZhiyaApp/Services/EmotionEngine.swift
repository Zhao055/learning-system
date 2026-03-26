import Foundation
import SwiftUI

final class EmotionEngine: ObservableObject {
    static let shared = EmotionEngine()

    @Published var currentMood: DetectedMood = .neutral
    @Published var zhiyaEmotion: ZhiyaEmotion = .gazing
    @Published private(set) var profile: EmotionalProfile = EmotionalProfile()

    private let profileKey = "zhiya_emotional_profile"

    private init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let p = try? JSONDecoder().decode(EmotionalProfile.self, from: data) {
            profile = p
        }
    }

    // MARK: - Mood Detection (from text)

    /// Detect mood from user's text input — 体贴品格的落地
    func detectMoodFromText(_ text: String) {
        let lower = text.lowercased()

        // 情绪关键词检测
        let frustrationWords = ["不会", "太难", "不行", "做不出", "放弃", "搞不懂", "不想学", "学不会", "不理解", "算了"]
        let anxietyWords = ["压力", "焦虑", "紧张", "害怕", "考试", "来不及", "怎么办"]
        let lowEnergyWords = ["累", "困", "烦", "无聊", "没意思", "不想", "懒"]
        let positiveWords = ["懂了", "明白了", "原来如此", "会了", "做对了", "开心", "有趣"]

        let frustrationCount = frustrationWords.filter { lower.contains($0) }.count
        let anxietyCount = anxietyWords.filter { lower.contains($0) }.count
        let lowEnergyCount = lowEnergyWords.filter { lower.contains($0) }.count
        let positiveCount = positiveWords.filter { lower.contains($0) }.count

        // 取最强信号
        let maxNegative = max(frustrationCount, anxietyCount, lowEnergyCount)

        if positiveCount > 0 && maxNegative == 0 {
            currentMood = .smooth
            zhiyaEmotion = .happy
            recordMood(.smooth, score: 0.8, context: text)
        } else if frustrationCount >= maxNegative && frustrationCount > 0 {
            currentMood = .frustrated
            zhiyaEmotion = .caring
            recordMood(.frustrated, score: 0.2, context: text)
        } else if anxietyCount >= maxNegative && anxietyCount > 0 {
            currentMood = .anxious
            zhiyaEmotion = .caring
            recordMood(.anxious, score: 0.3, context: text)
        } else if lowEnergyCount >= maxNegative && lowEnergyCount > 0 {
            currentMood = .lowEnergy
            zhiyaEmotion = .calm
            recordMood(.lowEnergy, score: 0.4, context: text)
        }
        // 如果没有匹配，保持当前 mood 不变
    }

    // MARK: - Mood Detection (from quiz behavior)

    func updateFromQuizResult(correct: Bool, consecutiveWrong: Int) {
        if correct {
            if consecutiveWrong == 0 {
                // First-try correct
                currentMood = .smooth
                zhiyaEmotion = .happy
            } else {
                // Correct after some wrong answers — celebrate recovery
                currentMood = .smooth
                zhiyaEmotion = .excited
                recordMood(.smooth, score: 0.8, context: "经历挫折后答对了")
            }
        } else if consecutiveWrong >= 3 {
            currentMood = .frustrated
            zhiyaEmotion = .caring
            recordMood(.frustrated, score: 0.2, context: "连续\(consecutiveWrong)题答错")
        } else if consecutiveWrong >= 2 {
            currentMood = .lowEnergy
            zhiyaEmotion = .caring
        } else {
            currentMood = .neutral
            zhiyaEmotion = .thinking
        }
    }

    func updateFromTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour < 6 {
            zhiyaEmotion = .sleeping
        } else if hour >= 21 {
            zhiyaEmotion = .caring // Late study
        }
    }

    func updateForChatState(_ state: ChatState) {
        switch state {
        case .idle: zhiyaEmotion = .gazing
        case .thinking: zhiyaEmotion = .thinking
        case .responding: zhiyaEmotion = .gazing
        case .celebrating: zhiyaEmotion = .excited
        }
    }

    // MARK: - Profile Accumulation

    func recordMood(_ mood: DetectedMood, score: Double, context: String = "") {
        let entry = MoodEntry(mood: mood, score: score, context: context)
        profile.recentMoods.append(entry)
        if profile.recentMoods.count > 100 {
            profile.recentMoods = Array(profile.recentMoods.suffix(100))
        }
        saveProfile()
    }

    // MARK: - UI Adaptation

    var backgroundColor: Color {
        switch currentMood {
        case .smooth: return ZhiyaTheme.smoothBackground
        case .frustrated: return ZhiyaTheme.frustratedBackground
        case .lowEnergy: return ZhiyaTheme.lowEnergyBackground
        case .anxious: return ZhiyaTheme.anxiousBackground
        case .neutral: return ZhiyaTheme.cream
        }
    }

    var shouldSimplifyUI: Bool {
        currentMood == .anxious
    }

    var warmModeActive: Bool {
        currentMood == .frustrated || currentMood == .lowEnergy
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
}

enum ChatState {
    case idle, thinking, responding, celebrating
}
