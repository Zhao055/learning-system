import SwiftUI

struct WeeklyLetterView: View {
    @State private var letter: WeeklyLetter?

    var body: some View {
        Group {
            if let letter = letter {
                ScrollView {
                    VStack(spacing: 0) {
                        // Letter card
                        VStack(spacing: 20) {
                            // Header
                            HStack {
                                Spacer()
                                Text("知芽的信")
                                    .font(ZhiyaTheme.heading())
                                    .foregroundColor(ZhiyaTheme.darkBrown)
                                Spacer()
                            }

                            // Date
                            Text("\(letter.weekStart.formatted(date: .abbreviated, time: .omitted)) - \(letter.weekEnd.formatted(date: .abbreviated, time: .omitted))")
                                .font(ZhiyaTheme.caption())
                                .foregroundColor(ZhiyaTheme.lightBrown)

                            Divider()
                                .background(ZhiyaTheme.warmGold)

                            // Topics
                            VStack(alignment: .leading, spacing: 8) {
                                Text("这周你学了：")
                                    .font(ZhiyaTheme.label())
                                    .foregroundColor(ZhiyaTheme.darkBrown)
                                ForEach(letter.topicsStudied, id: \.self) { topic in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(ZhiyaTheme.softTeal)
                                            .frame(width: 6, height: 6)
                                        Text(topic)
                                            .font(ZhiyaTheme.body(14))
                                            .foregroundColor(ZhiyaTheme.darkBrown)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Observation
                            Text(letter.observation)
                                .font(ZhiyaTheme.body())
                                .foregroundColor(ZhiyaTheme.darkBrown)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Suggestion
                            Text(letter.suggestion)
                                .font(ZhiyaTheme.body(14))
                                .foregroundColor(ZhiyaTheme.lightBrown)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Divider()
                                .background(ZhiyaTheme.warmGold)

                            // Closing
                            Text(letter.closing)
                                .font(ZhiyaTheme.body())
                                .foregroundColor(ZhiyaTheme.darkBrown)

                            // Signature
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    ZhiyaMascotView(emotion: .happy, size: 28)
                                    Text("知芽")
                                        .font(ZhiyaTheme.label())
                                        .foregroundColor(ZhiyaTheme.goldenAmber)
                                }
                            }
                        }
                        .padding(24)
                        .background(ZhiyaTheme.ivory)
                        .cornerRadius(ZhiyaTheme.cornerRadiusLG)
                        .overlay(
                            RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadiusLG)
                                .stroke(ZhiyaTheme.warmGold.opacity(0.5), lineWidth: 2)
                        )
                        .shadow(color: ZhiyaTheme.softShadowColor, radius: 12, y: 6)
                        .padding()
                    }
                }
            } else {
                EmptyStateView(
                    icon: "envelope.fill",
                    title: "每周信件",
                    message: "每周日，知芽会给你写一封信，回顾这周的学习和成长。"
                )
            }
        }
        .background(ZhiyaTheme.cream.ignoresSafeArea())
        .navigationTitle("每周信件")
        .onAppear {
            letter = MemoryService.shared.latestLetter()
        }
    }
}
