import SwiftUI

final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case greeting = 0
        case name
        case subjects
        case goals
        case planting
    }

    @Published var currentStep: Step = .greeting
    @Published var childName: String = ""
    @Published var selectedSubjects: Set<String> = []
    @Published var goals: String = ""
    @Published var isAnimating: Bool = false
    @Published var seedCracked: Bool = false
    @Published var sproutVisible: Bool = false

    var zhiyaMessages: [String] {
        switch currentStep {
        case .greeting:
            return ["你好，我是知芽。", "我会陪你一起学习、一起成长。", "先让我认识你吧？"]
        case .name:
            return ["你叫什么名字？"]
        case .subjects:
            return ["你在学哪些科目？"]
        case .goals:
            return ["你有什么目标吗？", "大的小的都可以。"]
        case .planting:
            return ["这是你成长之旅的第一天。", "以后每一天，我都在。"]
        }
    }

    func advance() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = next
        }
    }

    func canAdvance() -> Bool {
        switch currentStep {
        case .greeting: return true
        case .name: return !childName.trimmingCharacters(in: .whitespaces).isEmpty
        case .subjects: return !selectedSubjects.isEmpty
        case .goals: return true // optional
        case .planting: return true
        }
    }

    func completeOnboarding(companionEngine: CompanionEngine) {
        companionEngine.setupProfile(
            name: childName.trimmingCharacters(in: .whitespaces),
            subjects: Array(selectedSubjects),
            goals: goals
        )
    }
}
