import SwiftUI

struct AnnualReviewView: View {
    @EnvironmentObject var companion: CompanionEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Tree animation placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadiusLG)
                        .fill(
                            LinearGradient(
                                colors: [ZhiyaTheme.lightGreenBg, ZhiyaTheme.cream],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 250)

                    VStack(spacing: 12) {
                        ZhiyaMascotView(emotion: .excited, size: 64)
                        Text("你已经和知芽一起走过")
                            .font(ZhiyaTheme.body())
                            .foregroundColor(ZhiyaTheme.darkBrown)
                        Text("\(companion.profile.daysSinceJoin) 天")
                            .font(ZhiyaTheme.title(40))
                            .foregroundColor(ZhiyaTheme.goldenAmber)
                    }
                }
                .padding(.horizontal)

                // Stats summary
                let stats = ProgressService.shared.getTotalStats()
                ZhiyaCard {
                    VStack(spacing: 12) {
                        StatRow(label: "总共做题", value: "\(stats.totalAnswered)")
                        Divider()
                        StatRow(label: "正确", value: "\(stats.totalCorrect)")
                        Divider()
                        StatRow(label: "正确率", value: "\(Int(stats.accuracy * 100))%")
                        Divider()
                        StatRow(label: "里程碑", value: "\(MemoryService.shared.milestones.count)")
                    }
                }
                .padding(.horizontal)

                // Message
                ZhiyaCard {
                    VStack(spacing: 12) {
                        Text("知芽想对你说")
                            .font(ZhiyaTheme.label())
                            .foregroundColor(ZhiyaTheme.goldenAmber)
                        Text("每一步都算数。不管快慢，你一直在前进。")
                            .font(ZhiyaTheme.body())
                            .foregroundColor(ZhiyaTheme.darkBrown)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(ZhiyaTheme.cream.ignoresSafeArea())
        .navigationTitle("成长回顾")
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(ZhiyaTheme.body(14))
                .foregroundColor(ZhiyaTheme.lightBrown)
            Spacer()
            Text(value)
                .font(ZhiyaTheme.heading(18))
                .foregroundColor(ZhiyaTheme.darkBrown)
        }
    }
}
