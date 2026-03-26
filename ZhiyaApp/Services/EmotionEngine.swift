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
