import SwiftUI

struct CompanionView: View {
    @EnvironmentObject var companionEngine: CompanionEngine
    @StateObject private var vm: CompanionViewModel

    @State private var dragOffset: CGFloat = 0
    @State private var showGarden = false

    init(companionEngine: CompanionEngine) {
        _vm = StateObject(wrappedValue: CompanionViewModel(companionEngine: companionEngine))
    }

    var body: some View {
        ZStack {
            // Ambient background
            AmbientBackgroundView()

            // Main content with swipe gesture
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Garden (off-screen left)
                    GardenView()
                        .frame(width: geo.size.width)

                    // Companion (main)
                    companionContent
                        .frame(width: geo.size.width)
                }
                .offset(x: showGarden ? 0 : -geo.size.width)
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.width
                            if showGarden {
                                // In garden, allow drag right to go back to companion
                                dragOffset = max(0, min(translation, geo.size.width))
                            } else {
                                // In companion, allow drag left to show garden
                                dragOffset = max(-geo.size.width, min(0, translation))
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = geo.size.width * 0.3
                            withAnimation(.spring(duration: 0.4)) {
                                if showGarden && value.translation.width > threshold {
                                    showGarden = false
                                } else if !showGarden && value.translation.width < -threshold {
                                    showGarden = true
                                }
                                dragOffset = 0
                            }
                        }
                )
                .animation(.spring(duration: 0.4), value: showGarden)
            }

            // Celebration overlay
            if vm.showCelebration, let milestone = vm.currentMilestone {
                CelebrationView(milestone: milestone) {
                    vm.showCelebration = false
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $vm.showSettings) {
            NavigationView {
                SettingsView()
                    .environmentObject(companionEngine)
            }
        }
        .sheet(isPresented: $vm.showCamera) {
            CameraInputSheet(isPresented: $vm.showCamera) { imageData in
                vm.sendImage(imageData)
            }
        }
        .onAppear {
            vm.generateProactiveMessages()
        }
        .onChange(of: vm.showGarden) { showGarden = vm.showGarden }
    }

    // MARK: - Companion Content

    private var companionContent: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar

            // Mascot area — collapses when actively chatting
            if !vm.mascotCollapsed {
                mascotArea
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Collapsed mascot: small inline version
                HStack(spacing: 8) {
                    ZhiyaMascotView(emotion: EmotionEngine.shared.zhiyaEmotion, size: 28)
                    Text("知芽")
                        .font(ZhiyaTheme.caption(13))
                        .foregroundColor(ZhiyaTheme.lightBrown)
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.3)) { vm.mascotCollapsed = false }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(ZhiyaTheme.lightBrown.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .transition(.opacity)
            }

            // Chat area
            chatArea

            // Voice overlay or input bar
            if vm.isRecording {
                VoiceInputView(isRecording: $vm.isRecording) { transcription in
                    vm.inputText = transcription
                    vm.sendMessage()
                }
                .frame(height: 200)
                .transition(.move(edge: .bottom))
            } else {
                CompanionInputBar(
                    inputText: $vm.inputText,
                    isLoading: vm.isLoading,
                    onSend: { vm.sendMessage() },
                    onCamera: { vm.showCamera = true },
                    onVoice: { withAnimation { vm.isRecording = true } }
                )
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Garden hint
            Button {
                withAnimation(.spring(duration: 0.4)) { showGarden = true }
            } label: {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "A8D5BA"))
            }

            Spacer()

            // Stage badge
            Text(companionEngine.profile.stage.label)
                .font(ZhiyaTheme.caption(12))
                .foregroundColor(Color(hex: "E8C9A0"))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "E8C9A0").opacity(0.2))
                .cornerRadius(12)

            Spacer()

            // Settings
            Button {
                vm.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "E8C9A0"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(hex: "4A3728"))
    }

    // MARK: - Mascot Area

    private var mascotArea: some View {
        VStack(spacing: 8) {
            Spacer()

            ZhiyaMascotView(
                emotion: EmotionEngine.shared.zhiyaEmotion,
                size: 100
            )
            .onTapGesture {
                withAnimation(.spring(duration: 0.3)) { vm.mascotCollapsed = true }
            }

            Text("知芽")
                .font(ZhiyaTheme.caption(13))
                .foregroundColor(ZhiyaTheme.lightBrown)

            // Subtle hint to tap
            if vm.messages.isEmpty {
                Text("点击开始对话")
                    .font(ZhiyaTheme.caption(11))
                    .foregroundColor(ZhiyaTheme.lightBrown.opacity(0.5))
            }

            Spacer()
        }
        .frame(height: 200)
    }

    // MARK: - Chat Area

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Layout anchor — forces re-render when messages change
                    Text("m\(vm.messages.count)")
                        .font(.system(size: 1))
                        .opacity(0.01)
                        .frame(height: 1)
                    ForEach(vm.messages.filter { $0.role != .system }) { message in
                        RichMessageView(
                            message: message,
                            onChallengeAnswer: { msgId, idx in
                                vm.handleChallengeAnswer(messageId: msgId, selectedIndex: idx)
                            },
                            onSuggestionTap: { msgId in
                                vm.handleSuggestionTap(messageId: msgId)
                            }
                        )
                        .id(message.id)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: vm.messages.count) {
                if let last = vm.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}
