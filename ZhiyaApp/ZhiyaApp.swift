import SwiftUI

@main
struct ZhiyaApp: App {
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var companionEngine = CompanionEngine()

    var body: some Scene {
        WindowGroup {
            if !hasCompletedSetup {
                WelcomeSetupView()
            } else if !hasCompletedOnboarding {
                SeedMomentView()
                    .environmentObject(companionEngine)
            } else {
                CompanionView(companionEngine: companionEngine)
                    .environmentObject(companionEngine)
            }
        }
    }
}
