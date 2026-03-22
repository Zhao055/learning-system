import SwiftUI

@main
struct ZhiyaApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var companionEngine = CompanionEngine()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                CompanionView(companionEngine: companionEngine)
                    .environmentObject(companionEngine)
            } else {
                SeedMomentView()
                    .environmentObject(companionEngine)
            }
        }
    }
}
