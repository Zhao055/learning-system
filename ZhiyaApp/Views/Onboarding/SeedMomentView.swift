import SwiftUI

struct SeedMomentView: View {
    @EnvironmentObject var companion: CompanionEngine
    @StateObject private var vm = OnboardingViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var chatMessages: [OnboardingMessage] = []
    @State private var showInput = false
    @State private var inputText = ""
    @State private var showSeedAnimation = false
    @State private var showSubjectSheet = false
    @FocusState private var inputFocused: Bool

    struct OnboardingMessage: Identifiable {
        let id = UUID()
        let isZhiya: Bool
        let content: String
    }

    var body: some View {
        ZStack {
            AmbientBackgroundView()

            VStack(spacing: 0) {
                // Mascot
                VStack(spacing: 8) {
                    if showSeedAnimation {
                        seedMomentImage
                            .scaleEffect(showSeedAnimation ? 1.0 : 0.3)
                            .opacity(showSeedAnimation ? 1.0 : 0.0)
                            .shadow(color: Color(hex: "A8D5BA").opacity(0.6), radius: 20, x: 0, y: 0)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "A8D5BA").opacity(0.2))
                                    .scaleEffect(showSeedAnimation ? 2.0 : 0.5)
                                    .opacity(showSeedAnimation ? 0.0 : 0.8)
                                    .animation(.easeOut(duration: 1.2), value: showSeedAnimation)
                            )
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                            .animation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0), value: showSeedAnimation)
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
                            Text("\(chatMessages.count)")
                                .font(.system(size: 1)).opacity(0.001).frame(height: 0.1)
                            ForEach(chatMessages) { msg in
                                Text(msg.content)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(Color(hex: "4A3728"))
                                    .padding(12)
                                    .background(msg.isZhiya ? Color(hex: "A8D5BA") : Color(hex: "D4A574"))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                                    .id(msg.id)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: chatMessages.count) {
                        if let last = chatMessages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Input area
                if showInput {
                    VStack(spacing: 0) {
                        Divider()

                        if vm.currentStep == .planting {
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
                            .background(Color(hex: "4A3728"))
                        } else {
                            // Text input for name & goals
                            HStack(spacing: 10) {
                                TextField(inputPlaceholder, text: $inputText)
                                    .font(ZhiyaTheme.body(15))
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "D4A574").opacity(0.4), lineWidth: 1))
                                    .focused($inputFocused)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            inputFocused = true
                                        }
                                    }
                                    .onSubmit { submitInput() }

                                Button { submitInput() } label: {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                            ? ZhiyaTheme.warmGold.opacity(0.4)
                                            : ZhiyaTheme.goldenAmber)
                                }
                                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color(hex: "4A3728"))
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear { startConversation() }
        .sheet(isPresented: $showSubjectSheet) {
            SubjectPickerSheet(selectedSubjects: $vm.selectedSubjects) {
                showSubjectSheet = false
                confirmSubjects()
            }
        }
    }

    // MARK: - Conversation Flow

    private func startConversation() {
        addZhiyaMessage("嗨，我是知芽。", delay: 0.5) {
            self.addZhiyaMessage("你叫什么名字？", delay: 0.8) {
                self.vm.currentStep = .name
                withAnimation { self.showInput = true }
            }
        }
    }

    private func submitInput() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        chatMessages.append(OnboardingMessage(isZhiya: false, content: text))
        inputText = ""

        switch vm.currentStep {
        case .name:
            vm.childName = text
            withAnimation { showInput = false }
            addZhiyaMessage("\(text)，认识你很高兴。我会一直在。", delay: 0.6) {
                self.addZhiyaMessage("你在学什么？", delay: 0.8) {
                    self.vm.currentStep = .subjects
                    self.showSubjectSheet = true
                }
            }

        case .goals:
            vm.goals = text
            withAnimation { showInput = false }
            addZhiyaMessage("了解了。我帮你种了一颗种子 🌱", delay: 0.6) {
                withAnimation(.spring(duration: 0.8)) { self.showSeedAnimation = true }
                self.addZhiyaMessage("以后每一天，我都在。想聊什么都可以。", delay: 1.2) {
                    self.vm.currentStep = .planting
                    withAnimation { self.showInput = true }
                }
            }

        default:
            break
        }
    }

    private func confirmSubjects() {
        let subjectNames = vm.selectedSubjects.compactMap { SubjectData.getSubject($0)?.nameCn }
        chatMessages.append(OnboardingMessage(isZhiya: false, content: subjectNames.joined(separator: "、")))

        addZhiyaMessage("好的。有没有什么考试快到了，或者有什么目标？", delay: 0.6) {
            self.vm.currentStep = .goals
            withAnimation { self.showInput = true }
        }
    }

    private func completePlanting() {
        vm.completeOnboarding(companionEngine: companion)
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }

    private func addZhiyaMessage(_ text: String, delay: Double, completion: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.chatMessages.append(OnboardingMessage(isZhiya: true, content: text))
            }
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    completion()
                }
            }
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
                    .foregroundColor(Color(hex: "7BC88F"))
            }
        }
    }

    private var inputPlaceholder: String {
        switch vm.currentStep {
        case .name: return "你的名字"
        case .goals: return "比如：A-Level拿A*"
        default: return "输入..."
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
                    .foregroundColor(Color(hex: "4A3728"))
                Spacer()
                Button {
                    onConfirm()
                } label: {
                    Text("确定")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedSubjects.isEmpty ? .gray : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedSubjects.isEmpty ? Color.gray.opacity(0.3) : Color(hex: "D4A574"))
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
                                    .foregroundColor(Color(hex: "4A3728"))
                                Spacer()
                                if selectedSubjects.contains(subject.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color(hex: "D4A574"))
                                } else {
                                    Image(systemName: "circle")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color(hex: "A8D5BA"))
                                }
                            }
                            .padding(16)
                            .background(
                                selectedSubjects.contains(subject.id)
                                    ? Color(hex: "D4A574").opacity(0.15)
                                    : Color(hex: "A8D5BA").opacity(0.15)
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        selectedSubjects.contains(subject.id)
                                            ? Color(hex: "D4A574").opacity(0.5)
                                            : Color(hex: "A8D5BA").opacity(0.3),
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
        .background(Color(hex: "FFF8F0"))
        .presentationDetents([.medium])
        .presentationCornerRadius(28)
    }
}
