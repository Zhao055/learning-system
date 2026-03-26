import SwiftUI

/// Dispatches rendering based on message type.
/// All sub-bubbles receive `availableWidth` for explicit width constraints.
struct RichMessageView: View {
    let message: ChatMessage
    let availableWidth: CGFloat
    let onChallengeAnswer: (String, Int) -> Void
    let onSuggestionTap: (String) -> Void

    var body: some View {
        switch message.messageType {
        case .text:
            ChatBubbleView(message: message, availableWidth: availableWidth)

        case .challengeCard:
            if let challenge = message.challengeData {
                VStack(alignment: .leading, spacing: 8) {
                    if !message.content.isEmpty {
                        AssistantBubble(text: message.content, availableWidth: availableWidth)
                    }
                    ChallengeCardView(
                        messageId: message.id,
                        challenge: challenge,
                        availableWidth: availableWidth,
                        onAnswer: onChallengeAnswer
                    )
                    .padding(.leading, 28)
                }
            }

        case .imageAnalysis:
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(ZhiyaTheme.cornerRadius)
                        .frame(maxWidth: availableWidth * 0.75,
                               alignment: message.role == .user ? .trailing : .leading)
                        .padding(.horizontal, 12)
                }
                if !message.content.isEmpty {
                    ChatBubbleView(message: message, availableWidth: availableWidth)
                }
            }

        case .growthSnapshot:
            GrowthSnapshotBubble(message: message, availableWidth: availableWidth)

        case .weeklyLetter:
            WeeklyLetterBubble(message: message, availableWidth: availableWidth)

        case .celebration:
            ChatBubbleView(message: message, availableWidth: availableWidth)

        case .suggestion:
            SuggestionBubble(message: message, availableWidth: availableWidth, onTap: onSuggestionTap)

        case .studyPlan:
            StudyPlanBubble(message: message, availableWidth: availableWidth)
        }
    }
}

// MARK: - Assistant Bubble (reusable)

struct AssistantBubble: View {
    let text: String
    let availableWidth: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZhiyaAvatarSmall()
                .offset(y: 4)
            Text(text)
                .font(ZhiyaTheme.body(15))
                .foregroundColor(ZhiyaTheme.darkBrown)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: availableWidth * 0.75, alignment: .leading)
                .background(ZhiyaTheme.bubbleGreen)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: ZhiyaTheme.softShadowColor, radius: 3, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

// MARK: - Suggestion Bubble

struct SuggestionBubble: View {
    let message: ChatMessage
    let availableWidth: CGFloat
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !message.content.isEmpty {
                AssistantBubble(text: message.content, availableWidth: availableWidth)
            }

            if let suggestion = message.suggestionData {
                HStack {
                    Spacer().frame(width: 40)
                    Button {
                        onTap(message.id)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: suggestion.tapped ? "checkmark.circle.fill" : "sparkles")
                                .font(.system(size: 14))
                            Text(suggestion.text)
                                .font(ZhiyaTheme.label(14))
                        }
                        .foregroundColor(suggestion.tapped ? ZhiyaTheme.lightBrown : ZhiyaTheme.goldenAmber)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(suggestion.tapped ? ZhiyaTheme.warmGold.opacity(0.1) : ZhiyaTheme.goldenAmber.opacity(0.12))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(ZhiyaTheme.goldenAmber.opacity(0.3), lineWidth: suggestion.tapped ? 0 : 1)
                        )
                    }
                    .disabled(suggestion.tapped)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Growth Snapshot Bubble

struct GrowthSnapshotBubble: View {
    let message: ChatMessage
    let availableWidth: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZhiyaAvatarSmall()
                .offset(y: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(message.content)
                    .font(ZhiyaTheme.body(15))
                    .foregroundColor(ZhiyaTheme.darkBrown)

                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(ZhiyaTheme.leafGreen)
                        .font(.system(size: 16))
                    Text("新叶子长出来了！")
                        .font(ZhiyaTheme.caption(13))
                        .foregroundColor(ZhiyaTheme.softTeal)
                }
                .padding(10)
                .background(ZhiyaTheme.lightGreenBg.opacity(0.5))
                .cornerRadius(12)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: availableWidth * 0.75, alignment: .leading)
            .background(ZhiyaTheme.bubbleGreen)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: ZhiyaTheme.softShadowColor, radius: 3, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

// MARK: - Weekly Letter Bubble

struct WeeklyLetterBubble: View {
    let message: ChatMessage
    let availableWidth: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZhiyaAvatarSmall()
                .offset(y: 4)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(ZhiyaTheme.goldenAmber)
                    Text("知芽的信")
                        .font(ZhiyaTheme.heading(16))
                        .foregroundColor(ZhiyaTheme.darkBrown)
                }

                Divider().background(ZhiyaTheme.bubbleGreen)

                Text(message.content)
                    .font(ZhiyaTheme.body(14))
                    .foregroundColor(ZhiyaTheme.darkBrown)

                Divider().background(ZhiyaTheme.bubbleGreen)

                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        ZhiyaAvatarSmall()
                        Text("知芽")
                            .font(ZhiyaTheme.caption(11))
                            .foregroundColor(ZhiyaTheme.goldenAmber)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: availableWidth - 44, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadius)
                    .stroke(ZhiyaTheme.warmGold.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: ZhiyaTheme.softShadowColor, radius: 8, y: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

// MARK: - Study Plan Bubble

struct StudyPlanBubble: View {
    let message: ChatMessage
    let availableWidth: CGFloat
    @State private var expanded = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZhiyaAvatarSmall()
                .offset(y: 4)

            VStack(alignment: .leading, spacing: 10) {
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(ZhiyaTheme.body(15))
                        .foregroundColor(ZhiyaTheme.darkBrown)
                }

                if let plan = message.studyPlanData {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation { expanded.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(ZhiyaTheme.softTeal)
                                Text(plan.title)
                                    .font(ZhiyaTheme.label())
                                    .foregroundColor(ZhiyaTheme.darkBrown)
                                Spacer()
                                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                    .foregroundColor(ZhiyaTheme.lightBrown)
                                    .font(.system(size: 12))
                            }
                        }
                        .buttonStyle(.plain)

                        if expanded {
                            ForEach(plan.items) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.completed ? ZhiyaTheme.integrity : ZhiyaTheme.lightBrown.opacity(0.5))
                                        .font(.system(size: 14))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.day)
                                            .font(ZhiyaTheme.caption(12))
                                            .foregroundColor(ZhiyaTheme.lightBrown)
                                        Text(item.topic)
                                            .font(ZhiyaTheme.body(14))
                                            .foregroundColor(ZhiyaTheme.darkBrown)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(ZhiyaTheme.cream.opacity(0.5))
                    .cornerRadius(ZhiyaTheme.cornerRadiusSM)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: availableWidth - 44, alignment: .leading)
            .background(ZhiyaTheme.bubbleGreen)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: ZhiyaTheme.softShadowColor, radius: 3, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}
