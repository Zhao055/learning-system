import SwiftUI

/// Dispatches rendering based on message type
struct RichMessageView: View {
    let message: ChatMessage
    let onChallengeAnswer: (String, Int) -> Void
    let onSuggestionTap: (String) -> Void

    var body: some View {
        switch message.messageType {
        case .text:
            ChatBubbleView(message: message)

        case .challengeCard:
            if let challenge = message.challengeData {
                VStack(alignment: .leading, spacing: 8) {
                    // Zhiya intro text
                    if !message.content.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                    .fill(Color(hex: "8FD4A4"))
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "leaf.fill").font(.system(size: 10)).foregroundColor(.white))
                                .offset(y: 4)
                            Text(message.content)
                                .font(ZhiyaTheme.body(15))
                                .foregroundColor(ZhiyaTheme.darkBrown)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(hex: "A8D5BA"))
                .cornerRadius(16)
                .shadow(color: ZhiyaTheme.softShadowColor, radius: 3, y: 2)
                                .cornerRadius(16)
                                .cornerRadius(4, corners: [.bottomLeft])
                            Spacer(minLength: 40)
                        }
                    }
                    // Challenge card
                    ChallengeCardView(
                        messageId: message.id,
                        challenge: challenge,
                        onAnswer: onChallengeAnswer
                    )
                    .padding(.leading, 28)
                }
            }

        case .imageAnalysis:
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                    HStack {
                        if message.role == .user { Spacer(minLength: 40) }
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(ZhiyaTheme.cornerRadius)
                        if message.role != .user { Spacer(minLength: 40) }
                    }
                }
                if !message.content.isEmpty {
                    ChatBubbleView(message: message)
                }
            }

        case .growthSnapshot:
            GrowthSnapshotBubble(message: message)

        case .weeklyLetter:
            WeeklyLetterBubble(message: message)

        case .celebration:
            ChatBubbleView(message: message)

        case .suggestion:
            SuggestionBubble(message: message, onTap: onSuggestionTap)

        case .studyPlan:
            StudyPlanBubble(message: message)
        }
    }
}

// MARK: - Suggestion Bubble

private struct SuggestionBubble: View {
    let message: ChatMessage
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text content
            if !message.content.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                    .fill(Color(hex: "8FD4A4"))
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "leaf.fill").font(.system(size: 10)).foregroundColor(.white))
                        .offset(y: 4)
                    Text(message.content)
                        .font(ZhiyaTheme.body(15))
                        .foregroundColor(ZhiyaTheme.darkBrown)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(hex: "A8D5BA"))
                .cornerRadius(16)
                .shadow(color: ZhiyaTheme.softShadowColor, radius: 3, y: 2)
                        .cornerRadius(16)
                        .cornerRadius(4, corners: [.bottomLeft])
                    Spacer(minLength: 40)
                }
            }

            // Suggestion button
            if let suggestion = message.suggestionData {
                HStack {
                    Spacer().frame(width: 28)
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
                        .background(
                            suggestion.tapped
                                ? ZhiyaTheme.warmGold.opacity(0.1)
                                : ZhiyaTheme.goldenAmber.opacity(0.12)
                        )
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

private struct GrowthSnapshotBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                    .fill(Color(hex: "8FD4A4"))
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "leaf.fill").font(.system(size: 10)).foregroundColor(.white))
                .offset(y: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(message.content)
                    .font(ZhiyaTheme.body(15))
                    .foregroundColor(ZhiyaTheme.darkBrown)

                // Mini tree animation
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(Color(hex: "7BC88F"))
                        .font(.system(size: 16))
                    Text("新叶子长出来了！")
                        .font(ZhiyaTheme.caption(13))
                        .foregroundColor(ZhiyaTheme.softTeal)
                }
                .padding(10)
                .background(Color(hex: "E8F5E9").opacity(0.5))
                .cornerRadius(12)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hex: "A8D5BA"))
                .cornerRadius(16)
                .shadow(color: ZhiyaTheme.softShadowColor, radius: 3, y: 2)
            .cornerRadius(16)
            .cornerRadius(4, corners: [.bottomLeft])

            Spacer(minLength: 40)
        }
    }
}

// MARK: - Weekly Letter Bubble

private struct WeeklyLetterBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                    .fill(Color(hex: "8FD4A4"))
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "leaf.fill").font(.system(size: 10)).foregroundColor(.white))
                .offset(y: 4)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(ZhiyaTheme.goldenAmber)
                    Text("知芽的信")
                        .font(ZhiyaTheme.heading(16))
                        .foregroundColor(ZhiyaTheme.darkBrown)
                }

                Divider()
                    .background(Color(hex: "A8D5BA"))

                Text(message.content)
                    .font(ZhiyaTheme.body(14))
                    .foregroundColor(ZhiyaTheme.darkBrown)

                Divider()
                    .background(Color(hex: "A8D5BA"))

                HStack {
                    Spacer()
                    // Use signature image if available, otherwise fallback
                    if ZhiyaImages.uiImage(.signature) != nil {
                        ZhiyaImages.signature
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    } else {
                        VStack(spacing: 2) {
                            Circle()
                    .fill(Color(hex: "8FD4A4"))
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "leaf.fill").font(.system(size: 10)).foregroundColor(.white))
                            Text("知芽")
                                .font(ZhiyaTheme.caption(11))
                                .foregroundColor(ZhiyaTheme.goldenAmber)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                // Use letter paper background if available
                Group {
                    if ZhiyaImages.uiImage(.letterPaperBg) != nil {
                        ZhiyaImages.letterPaperBg
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.white
                    }
                }
            )
            .cornerRadius(ZhiyaTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadius)
                    .stroke(ZhiyaTheme.warmGold.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: ZhiyaTheme.softShadowColor, radius: 8, y: 4)

            Spacer(minLength: 20)
        }
    }
}

// MARK: - Study Plan Bubble

private struct StudyPlanBubble: View {
    let message: ChatMessage
    @State private var expanded = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                    .fill(Color(hex: "8FD4A4"))
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "leaf.fill").font(.system(size: 10)).foregroundColor(.white))
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
            .background(Color(hex: "A8D5BA"))
                .cornerRadius(16)
                .shadow(color: ZhiyaTheme.softShadowColor, radius: 3, y: 2)
            .cornerRadius(16)
            .cornerRadius(4, corners: [.bottomLeft])

            Spacer(minLength: 40)
        }
    }
}
