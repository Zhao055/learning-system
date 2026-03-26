import SwiftUI

struct SeedMomentView: View {
    @EnvironmentObject var companion: CompanionEngine
    @StateObject private var coordinator = OnboardingChatCoordinator()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Mascot
            VStack(spacing: 8) {
                if coordinator.showSeedAnimation {
                    seedMomentImage
                        .scaleEffect(coordinator.showSeedAnimation ? 1.0 : 0.3)
                        .opacity(coordinator.showSeedAnimation ? 1.0 : 0.0)
                        .shadow(color: ZhiyaTheme.bubbleGreen.opacity(0.6), radius: 20, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(ZhiyaTheme.bubbleGreen.opacity(0.2))
                                .scaleEffect(coordinator.showSeedAnimation ? 2.0 : 0.5)
                                .opacity(coordinator.showSeedAnimation ? 0.0 : 0.8)
                                .animation(.easeOut(duration: 1.2), value: coordinator.showSeedAnimation)
                        )
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                        .animation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0), value: coordinator.showSeedAnimation)
                } else {
                    ZhiyaMascotView(emotion: .gazing, size: 70)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 20)

            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Layout anchor — forces re-render when messages change
                        Text("\(coordinator.messages.count)")
                            .font(.system(size: 1)).opacity(0.001).frame(height: 0.1)
                        ForEach(coordinator.messages) { msg in
                            Text(msg.content)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(ZhiyaTheme.darkBrown)
                                .padding(12)
                                .background(msg.isZhiya ? ZhiyaTheme.bubbleGreen : ZhiyaTheme.goldenAmber)
                                .cornerRadius(16)
                                .padding(.horizontal, 16)
                                .id(msg.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: coordinator.messages.count) {
                    if let last = coordinator.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

        }
        .safeAreaInset(edge: .bottom) {
                if coordinator.showInput {
                    VStack(spacing: 0) {
                        Divider()

                        if coordinator.currentStep == .planting {
                            // "开始旅程" button
                            HStack {
                                Spacer()
                                Button { completePlanting() } label: {
                                    Text("开始旅程")
                                        .font(ZhiyaTheme.label())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(ZhiyaTheme.goldenAmber)
                                        .cornerRadius(20)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .background(.regularMaterial)
                        } else {
                            // Text input for name & goals
                            HStack(spacing: 10) {
                                TextField(coordinator.inputPlaceholder, text: $inputText)
                                    .font(ZhiyaTheme.body(16))
                                    .foregroundColor(ZhiyaTheme.darkBrown)
                                    .focused($inputFocused)
                                    .onSubmit { submitInput() }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(ZhiyaTheme.goldenAmber.opacity(0.4), lineWidth: 1))

                                Button { submitInput() } label: {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                            ? ZhiyaTheme.warmGold.opacity(0.4)
                                            : ZhiyaTheme.goldenAmber)
                                }
                                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || coordinator.isStreaming)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(.regularMaterial)
                            .onAppear { inputFocused = true }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        .background(AmbientBackgroundView().ignoresSafeArea())
        .onAppear { coordinator.startConversation() }
        .sheet(isPresented: $coordinator.showSubjectSheet) {
            SubjectPickerSheet(selectedSubjects: $coordinator.selectedSubjects) {
                coordinator.showSubjectSheet = false
                coordinator.confirmSubjects(coordinator.selectedSubjects)
            }
        }
    }

    // MARK: - Actions

    private func submitInput() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""

        switch coordinator.currentStep {
        case .awaitingName:
            coordinator.submitName(text)
        case .awaitingGoals:
            coordinator.submitGoals(text)
        default:
            break
        }
    }

    private func completePlanting() {
        coordinator.completeOnboarding(companionEngine: companion)
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }

    @ViewBuilder
    private var seedMomentImage: some View {
        if ZhiyaImages.uiImage(.seedMoment3) != nil {
            ZhiyaImages.seedMoment3
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 150)
                .cornerRadius(16)
        } else {
            VStack(spacing: 8) {
                ZhiyaMascotView(emotion: .excited, size: 100)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundColor(ZhiyaTheme.leafGreen)
            }
        }
    }
}

// MARK: - Subject Picker Sheet (renders outside LazyVStack to avoid rendering bugs)

private struct SubjectPickerSheet: View {
    @Binding var selectedSubjects: Set<String>
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar
            HStack {
                Text("选择科目")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(ZhiyaTheme.darkBrown)
                Spacer()
                Button {
                    onConfirm()
                } label: {
                    Text("确定")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedSubjects.isEmpty ? .gray : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedSubjects.isEmpty ? Color.gray.opacity(0.3) : ZhiyaTheme.goldenAmber)
                        .cornerRadius(16)
                }
                .disabled(selectedSubjects.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(SubjectData.subjects) { subject in
                        Button {
                            if selectedSubjects.contains(subject.id) {
                                selectedSubjects.remove(subject.id)
                            } else {
                                selectedSubjects.insert(subject.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(subject.icon)
                                    .font(.system(size: 28))
                                Text(subject.nameCn)
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(ZhiyaTheme.darkBrown)
                                Spacer()
                                if selectedSubjects.contains(subject.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(ZhiyaTheme.goldenAmber)
                                } else {
                                    Image(systemName: "circle")
                                        .font(.system(size: 22))
                                        .foregroundColor(ZhiyaTheme.bubbleGreen)
                                }
                            }
                            .padding(16)
                            .background(
                                selectedSubjects.contains(subject.id)
                                    ? ZhiyaTheme.goldenAmber.opacity(0.15)
                                    : ZhiyaTheme.bubbleGreen.opacity(0.15)
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        selectedSubjects.contains(subject.id)
                                            ? ZhiyaTheme.goldenAmber.opacity(0.5)
                                            : ZhiyaTheme.bubbleGreen.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(ZhiyaTheme.cream)
        .presentationDetents([.medium])
        .presentationCornerRadius(28)
    }
}
