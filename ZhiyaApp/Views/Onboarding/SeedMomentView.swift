import SwiftUI

struct SeedMomentView: View {
    @EnvironmentObject var companion: CompanionEngine
    @StateObject private var vm = OnboardingViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var chatMessages: [OnboardingMessage] = []
    @State private var showInput = false
    @State private var inputText = ""
    @State private var showSeedAnimation = false
    @FocusState private var inputFocused: Bool

    struct OnboardingMessage: Identifiable {
        let id = UUID()
        let isZhiya: Bool
        let content: String
        var isSubjectPicker: Bool = false
    }

    var body: some View {
        ZStack {
            // Background
            AmbientBackgroundView()

            VStack(spacing: 0) {
                // Mascot + Seed moment images
                VStack(spacing: 8) {
                    if showSeedAnimation {
                        // Show seed moment images based on step
                        seedMomentImage
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(duration: 0.6), value: showSeedAnimation)
                    } else {
                        ZhiyaMascotView(
                            emotion: .gazing,
                            size: 70
                        )
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Chat-style messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Layout anchor — required for LazyVStack to re-render on state changes
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

                            // Subject picker — uses opacity instead of if/else to avoid LazyVStack rendering bug
                            subjectPicker
                                .padding(.horizontal, 16)
                                .opacity(vm.currentStep == .subjects ? 1 : 0)
                                .frame(height: vm.currentStep == .subjects ? nil : 0)
                                .clipped()
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

                        if vm.currentStep == .subjects {
                            // Subject selection has its own confirm button
                            if !vm.selectedSubjects.isEmpty {
                                HStack {
                                    Spacer()
                                    Button {
                                        confirmSubjects()
                                    } label: {
                                        Text("确定")
                                            .font(ZhiyaTheme.label())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 10)
                                            .background(ZhiyaTheme.goldenAmber)
                                            .cornerRadius(20)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .background(Color(hex: "A8D5BA").opacity(0.3))
                            }
                        } else if vm.currentStep == .planting {
                            HStack {
                                Spacer()
                                Button {
                                    completePlanting()
                                } label: {
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
                            .background(Color(hex: "A8D5BA").opacity(0.3))
                        } else {
                            // Text input
                            HStack(spacing: 10) {
                                TextField(inputPlaceholder, text: $inputText)
                                    .font(ZhiyaTheme.body(15))
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(ZhiyaTheme.warmGold.opacity(0.5), lineWidth: 1))
                                    .focused($inputFocused)
                                    .onSubmit { submitInput() }

                                Button {
                                    submitInput()
                                } label: {
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
                            .background(Color(hex: "A8D5BA").opacity(0.3))
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startConversation()
        }
    }

    // MARK: - Bubble

    @ViewBuilder
    private func onboardingBubble(_ msg: OnboardingMessage) -> some View {
        HStack {
            if !msg.isZhiya { Spacer() }
            Text(msg.content)
                .font(ZhiyaTheme.body(16))
                .foregroundColor(msg.isZhiya ? ZhiyaTheme.darkBrown : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(msg.isZhiya ? Color.white : ZhiyaTheme.goldenAmber)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
            if msg.isZhiya { Spacer() }
        }
    }

    // MARK: - Subject Picker

    private var subjectPicker: some View {
        VStack(spacing: 8) {
            ForEach(SubjectData.subjects) { subject in
                Button {
                    if vm.selectedSubjects.contains(subject.id) {
                        vm.selectedSubjects.remove(subject.id)
                    } else {
                        vm.selectedSubjects.insert(subject.id)
                    }
                } label: {
                    HStack {
                        Text(subject.icon)
                        Text(subject.nameCn)
                            .font(ZhiyaTheme.body())
                            .foregroundColor(ZhiyaTheme.darkBrown)
                        Spacer()
                        if vm.selectedSubjects.contains(subject.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ZhiyaTheme.goldenAmber)
                        }
                    }
                    .padding(14)
                    .background(vm.selectedSubjects.contains(subject.id)
                        ? ZhiyaTheme.goldenAmber.opacity(0.3) : Color(hex: "A8D5BA").opacity(0.3))
                    .cornerRadius(ZhiyaTheme.cornerRadiusSM)
                    .overlay(
                        RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadiusSM)
                            .stroke(vm.selectedSubjects.contains(subject.id) ? ZhiyaTheme.goldenAmber : Color(hex: "A8D5BA").opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Conversation Flow

    private func startConversation() {
        // Step: greeting
        addZhiyaMessage("嗨，我是知芽。", delay: 0.5) {
            self.addZhiyaMessage("你叫什么名字？", delay: 0.8) {
                self.vm.currentStep = .name
                withAnimation { self.showInput = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.inputFocused = true }
            }
        }
    }

    private func submitInput() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        // Add user bubble
        chatMessages.append(OnboardingMessage(isZhiya: false, content: text))
        inputText = ""

        switch vm.currentStep {
        case .name:
            vm.childName = text
            withAnimation { showInput = false }
            addZhiyaMessage("\(text)，认识你很高兴。我会一直在。", delay: 0.6) {
                self.addZhiyaMessage("你在学什么？", delay: 0.8) {
                    self.vm.currentStep = .subjects
                    // Subject picker is shown via vm.currentStep == .subjects
                    withAnimation { self.showInput = true }
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

        withAnimation { showInput = false }

        addZhiyaMessage("好的。有没有什么考试快到了，或者有什么目标？", delay: 0.6) {
            self.vm.currentStep = .goals
            withAnimation { self.showInput = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.inputFocused = true }
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
            // Use the seedling in pot image for the planting animation
            ZhiyaImages.seedMoment3
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 150)
                .cornerRadius(16)
        } else {
            // Fallback: code-drawn animation
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

// MARK: - Onboarding Row (extracted to avoid if/else inside ForEach+LazyVStack)

private struct OnboardingRow: View {
    let msg: SeedMomentView.OnboardingMessage
    @Binding var selectedSubjects: Set<String>

    var body: some View {
        if msg.isSubjectPicker {
            VStack(spacing: 8) {
                ForEach(SubjectData.subjects) { subject in
                    Button {
                        if selectedSubjects.contains(subject.id) {
                            selectedSubjects.remove(subject.id)
                        } else {
                            selectedSubjects.insert(subject.id)
                        }
                    } label: {
                        HStack {
                            Text(subject.icon)
                            Text(subject.nameCn)
                                .font(ZhiyaTheme.body())
                                .foregroundColor(ZhiyaTheme.darkBrown)
                            Spacer()
                            if selectedSubjects.contains(subject.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ZhiyaTheme.goldenAmber)
                            }
                        }
                        .padding(14)
                        .background(selectedSubjects.contains(subject.id)
                            ? ZhiyaTheme.goldenAmber.opacity(0.1) : Color(hex: "F5F0EA"))
                        .cornerRadius(ZhiyaTheme.cornerRadiusSM)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            HStack {
                if !msg.isZhiya { Spacer() }
                Text(msg.content)
                    .font(ZhiyaTheme.body(16))
                    .foregroundColor(msg.isZhiya ? ZhiyaTheme.darkBrown : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(msg.isZhiya ? Color(hex: "F5F0EA") : ZhiyaTheme.goldenAmber)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.12), radius: 6, y: 3)
                if msg.isZhiya { Spacer() }
            }
        }
    }
}
