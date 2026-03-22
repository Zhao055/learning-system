import SwiftUI

struct ChallengeCardView: View {
    let messageId: String
    let challenge: ChallengeData
    let onAnswer: (String, Int) -> Void

    private let optionLabels = ["A", "B", "C", "D"]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Subject decoration image (faded, in corner)
            subjectDecoration
                .opacity(0.12)
                .frame(width: 80, height: 80)
                .clipped()
                .offset(x: 10, y: -10)

        VStack(alignment: .leading, spacing: 14) {
            // KP badge
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 11))
                Text(challenge.kpTitle)
                    .font(ZhiyaTheme.caption(12))
            }
            .foregroundColor(ZhiyaTheme.softTeal)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(ZhiyaTheme.softTeal.opacity(0.1))
            .cornerRadius(12)

            // Question stem
            Text(challenge.stem)
                .font(ZhiyaTheme.body(15))
                .foregroundColor(ZhiyaTheme.darkBrown)
                .fixedSize(horizontal: false, vertical: true)

            // Options
            VStack(spacing: 8) {
                ForEach(Array(challenge.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        if !challenge.answered {
                            onAnswer(messageId, index)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            // Option label circle
                            ZStack {
                                Circle()
                                    .fill(optionColor(for: index))
                                    .frame(width: 28, height: 28)
                                Text(optionLabels[index])
                                    .font(ZhiyaTheme.label(13))
                                    .foregroundColor(optionTextColor(for: index))
                            }

                            Text(option)
                                .font(ZhiyaTheme.body(14))
                                .foregroundColor(ZhiyaTheme.darkBrown)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            // Result indicator
                            if challenge.answered && index == challenge.correctIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ZhiyaTheme.integrity)
                            } else if challenge.answered && index == challenge.selectedIndex && challenge.isCorrect == false {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(ZhiyaTheme.empathy.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(optionBackground(for: index))
                        .cornerRadius(ZhiyaTheme.cornerRadiusSM)
                        .overlay(
                            RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadiusSM)
                                .stroke(optionBorderColor(for: index), lineWidth: challenge.answered ? 1.5 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(challenge.answered)
                }
            }

            // Difficulty indicator
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < challenge.difficulty ? ZhiyaTheme.goldenAmber : ZhiyaTheme.warmGold.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(ZhiyaTheme.ivory)
        .cornerRadius(ZhiyaTheme.cornerRadius)
        .shadow(color: ZhiyaTheme.softShadowColor, radius: 8, y: 4)
        .animation(.spring(duration: 0.3), value: challenge.answered)
        } // end ZStack
    }

    // MARK: - Subject Decoration

    @ViewBuilder
    private var subjectDecoration: some View {
        let paperId = challenge.paperId.lowercased()
        if paperId.hasPrefix("math") {
            ZhiyaImages.subjectMath
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if paperId.hasPrefix("bio") {
            ZhiyaImages.subjectBiology
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if paperId.hasPrefix("psych") {
            ZhiyaImages.subjectPsychology
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            EmptyView()
        }
    }

    // MARK: - Styling

    private func optionColor(for index: Int) -> Color {
        if !challenge.answered {
            return ZhiyaTheme.warmGold.opacity(0.15)
        }
        if index == challenge.correctIndex {
            return ZhiyaTheme.integrity
        }
        if index == challenge.selectedIndex && challenge.isCorrect == false {
            return ZhiyaTheme.empathy.opacity(0.7)
        }
        return ZhiyaTheme.warmGold.opacity(0.15)
    }

    private func optionTextColor(for index: Int) -> Color {
        if challenge.answered && (index == challenge.correctIndex || (index == challenge.selectedIndex && challenge.isCorrect == false)) {
            return .white
        }
        return ZhiyaTheme.darkBrown
    }

    private func optionBackground(for index: Int) -> Color {
        if !challenge.answered {
            return ZhiyaTheme.cream.opacity(0.5)
        }
        if index == challenge.correctIndex {
            return ZhiyaTheme.integrity.opacity(0.08)
        }
        if index == challenge.selectedIndex && challenge.isCorrect == false {
            return ZhiyaTheme.empathy.opacity(0.08)
        }
        return ZhiyaTheme.cream.opacity(0.3)
    }

    private func optionBorderColor(for index: Int) -> Color {
        if !challenge.answered {
            return ZhiyaTheme.warmGold.opacity(0.2)
        }
        if index == challenge.correctIndex {
            return ZhiyaTheme.integrity.opacity(0.5)
        }
        if index == challenge.selectedIndex && challenge.isCorrect == false {
            return ZhiyaTheme.empathy.opacity(0.5)
        }
        return ZhiyaTheme.warmGold.opacity(0.1)
    }
}
